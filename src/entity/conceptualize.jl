struct LinkTemplate
    node
    ltype::LinkStyle
    pos::SVector
end

mutable struct LinkNode
    term::Term
    ltype::Union{Nothing,LinkStyle}
    hvalue::UInt64
    bgt::Budget
    children::Vector{LinkNode}
    templates::Vector{LinkTemplate}
    termlinks::Vector{TermLink}
    tasklinks::Vector{TaskLink}
    function LinkNode(term::AbstractCompound, bgt)
        children = [LinkNode(comp, bgt) for comp in term.comps]
        new(term, linktype(term), hash(term), bgt, children, LinkTemplate[], TermLink[], TaskLink[])
    end
    # 构造节点树时暂不论节点是不是变量或者PlaceHolder
    LinkNode(term::Atom, bgt) = new(term, linktype(term), hash(term), bgt, LinkNode[], LinkTemplate[], TermLink[], TaskLink[])
    LinkNode(term::Negation, bgt) = new(term, linktype(term), hash(term), bgt, [LinkNode(term.ϕ, bgt)], LinkTemplate[], TermLink[], TaskLink[])
end


linktype(term::Atom) = nothing
linktype(term) = term isa Statement ? COMPONENT_STATEMENT : COMPONENT

Base.reverse(ltype::LinkStyle) = @match ltype begin
        COMPONENT => COMPOUND
        COMPONENT_CONDITION => COMPOUND_CONDITION
        COMPONENT_STATEMENT  => COMPOUND_STATEMENT
        TRANSFORM => TRANSFORM
        COMPOUND => COMPONENT
        COMPOUND_STATEMENT => COMPONENT_STATEMENT
        COMPOUND_CONDITION => COMPONENT_CONDITION
        _ => @error "No REV Matched!" ltype
    end

Gene.isconstant(n::LinkNode) = isconstant(n.term)
struct LinkTree
    root::LinkNode
    LinkTree(term, bgt) = new(LinkNode(term, bgt))
end

function preparetemplates!(node::LinkNode, rltype = linktype(node.term))
    for (idx, cnode) in enumerate(node.children)
        # ! first level
        if isconstant(cnode)
            template = LinkTemplate(cnode, rltype, SVector(idx))
            push!(node.templates, template)
            if cnode.term isa AbstractCompound
                preparetemplates!(cnode)
            end
        end
        ltype = rltype
        if (((node.term isa Equivalence) || ((node.term isa Implication) && idx == 1))
                && ((cnode.term isa Conjunction) || (cnode.term isa Negation)))
            ltype = COMPONENT_CONDITION
        end
        for (cidx, cc_node) in enumerate(cnode.children)
            # ! second level
            if isconstant(cc_node)
                if cnode.term isa Union{Product, Image} && node.term isa Inheritance
                    ltype = TRANSFORM
                end
                template = LinkTemplate(cc_node, ltype, SVector(idx, cidx))
                push!(node.templates, template)
            end
            for (ccidx, ccc_node) in enumerate(cc_node.children)
                # ! third level
                if isconstant(ccc_node)
                    if cc_node.term isa Union{Product, Image} && cnode.term isa Inheritance
                        ltype = TRANSFORM
                    end
                    template = LinkTemplate(ccc_node, ltype, SVector(idx, cidx, ccidx))
                    push!(node.templates, template)
                end
            end
        end
    end
end


function genlinks!(node, template)
    cnode = template.node
    ltype = template.ltype
    ltype == TRANSFORM && return
    down_token = Token(cnode.hvalue, deepcopy(node.bgt))
    up_token = Token(node.hvalue, deepcopy(node.bgt))
    push!(node.termlinks, TermLink(down_token, ltype, template.pos))
    push!(cnode.termlinks, TermLink(up_token, reverse(ltype), template.pos))
end

function addtasklink!(root::LinkNode, task)
    # -1 在 conddedind中表示自身
    tasklink = TaskLink(deepcopy(token(task)), task, SELF, SVector(-1))
    push!(root.tasklinks, tasklink)
    for template in root.templates
        tasklink = TaskLink(deepcopy(token(task)), task, reverse(template.ltype), template.pos)
        push!(template.node.tasklinks, tasklink)
    end
end

function buildtermlinks!(root::LinkNode)
    for template in root.templates
        genlinks!(root, template)
        buildtermlinks!(template.node)
    end
end

"""
概念化任务
返回所有相关概念
"""
function conceptualize(task::NaTask)
    linktree = LinkTree(task.sentence.term, bgt(task))
    preparetemplates!(linktree.root)
    distributebgt!(linktree.root)
    addtasklink!(linktree.root, task)
    buildtermlinks!(linktree.root)
    conceptualize(linktree, task)
end

function conceptualize(ltree::LinkTree, task::NaTask)
    concepts = Dict{UInt64, Concept}()
    root = ltree.root
    rootcpt = conceptualize!(root, concepts)
    if eltype(task.sentence) <: Judgement
        rootcpt.beliefs = Table{Belief}(deepcopy(task.sentence))
    end
    for template in root.templates
        conceptualize!(template.node, concepts)
    end
    return values(concepts)
end

function conceptualize!(node::LinkNode, concepts)
    !isconstant(node.term) && return
    self = Concept(node.term, node.bgt)
    for termlink in node.termlinks
        put!(self.termlinks, termlink)
    end
    for tasklink in node.tasklinks
        put!(self.tasklinks, tasklink)
        # activate!(self, tasklink)
    end
    concepts[node.hvalue] = self
    self
end

function distributebgt!(node::LinkNode, linknum = length(node.templates))
    node_bgt = node.bgt
    link_priority = node_bgt.priority / sqrt(linknum > 0 ? linknum : 1)
    subbgt = Budget(link_priority, node_bgt.durability, node_bgt.quality)
    for template in node.templates
        template.node.bgt = subbgt
        distributebgt!(template.node)
    end
end