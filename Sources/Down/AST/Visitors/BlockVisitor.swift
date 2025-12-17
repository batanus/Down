#if !os(Linux)

import Foundation

public enum Block {
    case document([Block])
    case blockQuote(NSAttributedString)
    case list(NSAttributedString)
    case item(NSAttributedString)
    case codeBlock(NSAttributedString, String?)
    case htmlBlock(NSAttributedString)
    case customBlock(NSAttributedString)
    case paragraph(NSAttributedString)
    case heading(NSAttributedString)
    case thematicBreak(NSAttributedString)
    case text(NSAttributedString)
    case softBreak(NSAttributedString)
    case lineBreak(NSAttributedString)
    case code(NSAttributedString)
    case htmlInline(NSAttributedString)
    case customInline(NSAttributedString)
    case emphasis(NSAttributedString)
    case strong(NSAttributedString)
    case link(NSAttributedString)
    case image(NSAttributedString)

    public var childBlocks: [Block] {
        switch self {
        case .document(let blocks): blocks
        default: []
        }
    }

    public var string: NSAttributedString {
        switch self {
        case .document(let block): block.first!.string
        case .blockQuote(let string): string
        case .list(let string): string
        case .item(let string): string
        case .codeBlock(let string, _): string
        case .htmlBlock(let string): string
        case .customBlock(let string): string
        case .paragraph(let string): string
        case .heading(let string): string
        case .thematicBreak(let string): string
        case .text(let string): string
        case .softBreak(let string): string
        case .lineBreak(let string): string
        case .code(let string): string
        case .htmlInline(let string): string
        case .customInline(let string): string
        case .emphasis(let string): string
        case .strong(let string): string
        case .link(let string): string
        case .image(let string): string
        }
    }
}

public class BlockVisitor {
    private let attributedStringVisitor: AttributedStringVisitor

    public init(attributedStringVisitor: AttributedStringVisitor) {
        self.attributedStringVisitor = attributedStringVisitor
    }
    
}

extension BlockVisitor: Visitor {
    public typealias Result = Block

    public func visit(document node: Document) -> Block {
        .document(visitChildren(of: node))
    }
    
    public func visit(blockQuote node: BlockQuote) -> Block {
        .blockQuote(attributedStringVisitor.visit(blockQuote: node))
    }
    
    public func visit(list node: List) -> Block {
        .list(attributedStringVisitor.visit(list: node))
    }
    
    public func visit(item node: Item) -> Block {
        .item(attributedStringVisitor.visit(item: node))
    }
    
    public func visit(codeBlock node: CodeBlock) -> Block {
        .codeBlock(attributedStringVisitor.visit(codeBlock: node), node.fenceInfo)
    }
    
    public func visit(htmlBlock node: HtmlBlock) -> Block {
        .htmlBlock(attributedStringVisitor.visit(htmlBlock: node))
    }
    
    public func visit(customBlock node: CustomBlock) -> Block {
        .customBlock(attributedStringVisitor.visit(customBlock: node))
    }
    
    public func visit(paragraph node: Paragraph) -> Block {
        .paragraph(attributedStringVisitor.visit(paragraph: node))
    }
    
    public func visit(heading node: Heading) -> Block {
        .heading(attributedStringVisitor.visit(heading: node))
    }
    
    public func visit(thematicBreak node: ThematicBreak) -> Block {
        .thematicBreak(attributedStringVisitor.visit(thematicBreak: node))
    }
    
    public func visit(text node: Text) -> Block {
        .text(attributedStringVisitor.visit(text: node))
    }
    
    public func visit(softBreak node: SoftBreak) -> Block {
        .softBreak(attributedStringVisitor.visit(softBreak: node))
    }
    
    public func visit(lineBreak node: LineBreak) -> Block {
        .lineBreak(attributedStringVisitor.visit(lineBreak: node))
    }
    
    public func visit(code node: Code) -> Block {
        .code(attributedStringVisitor.visit(code: node))
    }
    
    public func visit(htmlInline node: HtmlInline) -> Block {
        .htmlInline(attributedStringVisitor.visit(htmlInline: node))
    }
    
    public func visit(customInline node: CustomInline) -> Block {
        .customInline(attributedStringVisitor.visit(customInline: node))
    }
    
    public func visit(emphasis node: Emphasis) -> Block {
        .emphasis(attributedStringVisitor.visit(emphasis: node))
    }
    
    public func visit(strong node: Strong) -> Block {
        .strong(attributedStringVisitor.visit(strong: node))
    }
    
    public func visit(link node: Link) -> Block {
        .link(attributedStringVisitor.visit(link: node))
    }
    
    public func visit(image node: Image) -> Block {
        .image(attributedStringVisitor.visit(image: node))
    }
}

#endif // !os(Linux)
