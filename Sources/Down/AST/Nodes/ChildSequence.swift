//
//  ChildSequence.swift
//  Down
//
//  Created by Sven Weidauer on 05.10.2020
//

import libcmark

/// Sequence of child nodes.

public struct ChildSequence: Sequence {

    // MARK: - Properties
    let node: Node?

    let cmarkNode: CMarkNode

    // MARK: - Methods

    public func makeIterator() -> Iterator {
        return Iterator(node: node, cmarkNode: cmark_node_first_child(cmarkNode))
    }

}

// MARK: - Iterator

public extension ChildSequence {

    struct Iterator: IteratorProtocol {

        // MARK: - Properties
        let node: Node?

        var cmarkNode: CMarkNode?

        // MARK: - Methods

        public mutating func next() -> Node? {
            guard let cmarkNode = cmarkNode else { return nil }
            defer { self.cmarkNode = cmark_node_next(cmarkNode) }

            guard let result = cmarkNode.wrap(parent: self.node) else {
                assertionFailure("Couldn't wrap node of type: \(cmarkNode.type)")
                return nil
            }

            return result
        }

    }

}
