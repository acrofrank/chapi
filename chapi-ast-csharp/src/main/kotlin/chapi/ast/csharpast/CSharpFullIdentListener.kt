package chapi.ast.csharpast

import chapi.ast.antlr.CSharpParser
import chapi.ast.antlr.CSharpParser.Type_declarationContext
import chapi.domain.core.*
import chapi.infra.Stack

class CSharpFullIdentListener(val fileName: String) : CSharpAstListener() {
    private var codeContainer: CodeContainer = CodeContainer(FullName = fileName)
    private var currentContainer: CodeContainer = codeContainer
    private var containerStack: Stack<CodeContainer> = Stack<CodeContainer>()
    private var currentPackage: CodePackage = CodePackage()

    override fun enterCompilation_unit(ctx: CSharpParser.Compilation_unitContext?) {
        containerStack.push(codeContainer)
    }

    override fun enterUsing_directives(ctx: CSharpParser.Using_directivesContext?) {
        for (usingCtx in ctx!!.using_directive()) {
            handleDirective(usingCtx!!)
        }
    }

    private fun handleDirective(usingCtx: CSharpParser.Using_directiveContext) {
        val usingType = usingCtx::class.java.simpleName
        val codeImport = CodeImport()

        when (usingType) {
            "UsingNamespaceDirectiveContext" -> {
                val directiveCtx = usingCtx as CSharpParser.UsingNamespaceDirectiveContext
                codeImport.Source = directiveCtx.namespace_or_type_name().text
            }
            "UsingAliasDirectiveContext" -> {
                val alisCtx = usingCtx as CSharpParser.UsingAliasDirectiveContext

                codeImport.Source = alisCtx.namespace_or_type_name().text
                codeImport.AsName = alisCtx.identifier().text
            }
            else -> {
                println("handleDirective: $usingType")
            }
        }

        codeContainer.Imports += codeImport
    }

    override fun enterNamespace_member_declaration(ctx: CSharpParser.Namespace_member_declarationContext?) {
        val namespaceDeclaration = ctx!!.namespace_declaration()
        if (namespaceDeclaration != null) {
            if (namespaceDeclaration.qualified_identifier() != null) {
                val nsName = ctx.namespace_declaration().qualified_identifier().text
                val container = CodeContainer(
                    FullName = fileName,
                    PackageName = nsName
                )

                pushContainer(container)
            }
        }
    }

    private fun pushContainer(container: CodeContainer) {
        currentContainer = container

        val DEFAULT_CODE_CONTAINER = 1
        if (containerStack.elements.size > DEFAULT_CODE_CONTAINER) {
            val lastContainer = containerStack.elements.last()
            lastContainer.Containers += currentContainer
            containerStack.elements[containerStack.elements.size - 1] = lastContainer

            containerStack.push(currentContainer)
        } else {
            codeContainer.Containers += currentContainer
            containerStack.push(currentContainer)
            println(containerStack.elements.size)
        }
    }

    override fun exitNamespace_declaration(ctx: CSharpParser.Namespace_declarationContext?) {
        containerStack.pop()
    }

    override fun enterClass_definition(ctx: CSharpParser.Class_definitionContext?) {
        val className = ctx!!.identifier().text
        val codeDataStruct = CodeDataStruct(
            NodeName = className
        )

        val classMemberDeclarations = ctx.class_body().class_member_declarations()
        if (classMemberDeclarations != null) {
            for (classMemberDeclarationcontext in classMemberDeclarations.class_member_declaration()) {
                this.handleClassMember(classMemberDeclarationcontext, codeDataStruct)
            }
        }

        val parent = ctx.parent
        when (parent.javaClass.simpleName) {
            "Type_declarationContext" -> {
                val typeDecl = parent as Type_declarationContext
                codeDataStruct.Annotations = parseAnnotations(typeDecl.attributes())
            }
        }

        currentContainer.DataStructures += codeDataStruct
    }

    private fun parseAnnotations(attributes: CSharpParser.AttributesContext?): Array<CodeAnnotation> {
        var annotations = arrayOf<CodeAnnotation>();

        attributes?.attribute_section()?.forEach { it ->
            it.attribute_list().attribute().forEach { attr ->
                val annotation = CodeAnnotation(Name = attr.namespace_or_type_name().text)
                attr.attribute_argument().forEach {
                    annotation.KeyValues += AnnotationKeyValue(Value = it.text)
                }

                annotations += annotation
            }
        }

        return annotations
    }

    private fun handleClassMember(
        memberCtx: CSharpParser.Class_member_declarationContext?,
        codeDataStruct: CodeDataStruct
    ) {
        val memberDeclaration = memberCtx!!.common_member_declaration() ?: return

        val firstChild = memberDeclaration.getChild(0)
        var returnType = "";
        when (firstChild::class.java.simpleName) {
            "TerminalNodeImpl" -> {
                returnType = firstChild.text
            }
        }

        val annotations = parseAnnotations(memberCtx.attributes())
        val modifiers = buildFunctionModifiers(memberCtx)

        if (memberDeclaration.typed_member_declaration() != null) {
            val typedMember = memberDeclaration.typed_member_declaration()

            val methodDeclaration = typedMember.method_declaration()
            if (methodDeclaration != null) {
                val typeContext = typedMember.type_()
                if (typeContext != null) {
                    returnType = typeContext.text
                }

                codeDataStruct.Functions += createFunction(
                    returnType,
                    annotations,
                    codeDataStruct.Package,
                    modifiers,
                    methodDeclaration.method_member_name().text,
                    methodDeclaration.formal_parameter_list()
                )
            }
        }

        if (memberDeclaration.constructor_declaration() != null) {
            val constructorDecl = memberDeclaration.constructor_declaration()

            codeDataStruct.Functions += createFunction(
                returnType,
                annotations,
                codeDataStruct.Package,
                modifiers,
                constructorDecl.identifier().text,
                constructorDecl.formal_parameter_list()
            )
        }

        val methodDecl = memberDeclaration.method_declaration()
        if (methodDecl != null) {
            codeDataStruct.Functions += createFunction(
                returnType,
                annotations,
                codeDataStruct.Package,
                modifiers,
                methodDecl.method_member_name().text,
                methodDecl.formal_parameter_list()
            )
        }
    }

    private fun createFunction(
        returnType: String,
        annotations: Array<CodeAnnotation>,
        packageName: String,
        modifiers: Array<String>,
        methodName: String,
        formalParameterListcontext: CSharpParser.Formal_parameter_listContext?
    ): CodeFunction {

        val codeFunction = CodeFunction(
            Package = packageName,
            Name = methodName,
            ReturnType = returnType,
            Modifiers = modifiers,
            Annotations = annotations
        )

        if (formalParameterListcontext != null) {
            codeFunction.Parameters = this.buildFunctionParameters(formalParameterListcontext)
        }
        return codeFunction
    }

    private fun buildFunctionParameters(formalParameterList: CSharpParser.Formal_parameter_listContext?): Array<CodeProperty> {
        var parameters: Array<CodeProperty> = arrayOf()
        if (formalParameterList!!.fixed_parameters() != null) {
            for (fixedParamCtx in formalParameterList.fixed_parameters().fixed_parameter()) {
                val argDeclCtx = fixedParamCtx.arg_declaration()
                if (argDeclCtx != null) {
                    val parameter = CodeProperty(
                        TypeType = argDeclCtx.type_().text,
                        TypeValue = argDeclCtx.identifier().text
                    )

                    parameters += parameter
                }
            }
        }

        return parameters
    }

    private fun buildFunctionModifiers(memberCtx: CSharpParser.Class_member_declarationContext): Array<String> {
        var modifiers: Array<String> = arrayOf()
        val allMemberModifiers = memberCtx.all_member_modifiers()
        if (allMemberModifiers != null) {
            for (allMemberModifiercontext in allMemberModifiers.all_member_modifier()) {
                modifiers += allMemberModifiercontext.text
            }
        }
        return modifiers
    }

    fun getNodeInfo(): CodeContainer {
        return codeContainer
    }
}
