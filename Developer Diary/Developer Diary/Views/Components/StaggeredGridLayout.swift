//
//  StaggeredGridLayout.swift
//  Developer Diary
//
//  Created by Jeremie Berduck on 18/07/2025.
//

import SwiftUI

struct StaggeredGridLayout: Layout {
    let columns: Int
    let spacing: CGFloat
    let verticalOffset: CGFloat
    
    init(columns: Int = 2, spacing: CGFloat = 16, verticalOffset: CGFloat = 66) {
        self.columns = columns
        self.spacing = spacing
        self.verticalOffset = verticalOffset
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = (width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
        
        // Calculate 9:16 aspect ratio height
        let cardHeight = columnWidth * (16.0 / 9.0)
        
        // Calculate total height needed
        let rows = Int(ceil(Double(subviews.count) / Double(columns)))
        var totalHeight: CGFloat = 0
        
        if rows > 0 {
            // First row height
            totalHeight += cardHeight
            
            // Add height for additional rows
            if rows > 1 {
                totalHeight += CGFloat(rows - 1) * (cardHeight + spacing)
            }
            
            // Add the offset for second column (if we have items in second column)
            if subviews.count > 1 {
                totalHeight += verticalOffset
            }
        }
        
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = (bounds.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
        let cardHeight = columnWidth * (16.0 / 9.0)
        
        var columnHeights = Array(repeating: CGFloat(0), count: columns)
        
        // Apply initial offset to second column
        if columns > 1 && subviews.count > 1 {
            columnHeights[1] = verticalOffset
        }
        
        for (index, subview) in subviews.enumerated() {
            let column = index % columns
            let x = bounds.minX + (CGFloat(column) * (columnWidth + spacing))
            let y = bounds.minY + columnHeights[column]
            
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: columnWidth, height: cardHeight)
            )
            
            columnHeights[column] += cardHeight + spacing
        }
    }
}