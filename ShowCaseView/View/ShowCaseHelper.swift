//
//  ShowCaseHelper.swift
//  ShowCaseView
//
//  Created by Leo on 13/07/24.
//

import SwiftUI

extension View {
    @ViewBuilder
    func showCase(order: Int, title: String, cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous, scale: CGFloat = 1) -> some View {
        self
            .anchorPreference(key: HighlightAnchorKey.self, value: .bounds) { anchor in
                let hightlight = Highlight(anchor: anchor, title: title, cornerRadius: cornerRadius, style: style, scale: scale)
                return [order : hightlight]
            }
    }
}

struct ShowCaseRoot: ViewModifier {
    var showHighlights: Bool
    var onFinished: () -> ()
    
    @State private var highlightOrder: [Int] = []
    @State private var currentHighlight: Int = 0
    @State private var showView: Bool = true
    /// PopOver
    @State private var showTitle: Bool = false
    ///NameSpace ID for smooth shape transition
    @Namespace private var animation
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(HighlightAnchorKey.self, perform: { value in
                highlightOrder = Array(value.keys).sorted()
            })
            .overlayPreferenceValue(HighlightAnchorKey.self) { preferences in
                if highlightOrder.indices.contains(currentHighlight), showHighlights, showView {
                    if let highlight = preferences[highlightOrder[currentHighlight]] {
                        HighlightView(highlight)
                    }
                }
            }
    }
    
    @ViewBuilder
    func HighlightView(_ highlight: Highlight) -> some View {
        GeometryReader { proxy in
            let highlightRect = proxy[highlight.anchor]
            let safeArea = proxy.safeAreaInsets
            
            Rectangle()
                .fill(.black.opacity(0.5))
                .reverseMask {
                    Rectangle()
                        .matchedGeometryEffect(id: "HIGHLIGHTSHAPE", in: animation)
                    /// Adding Border
                    /// Simply Extends its size
                        .frame(width: highlightRect.width + 5, height: highlightRect.height + 5)
                        .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius, style: highlight.style))
                        .scaleEffect(highlight.scale)
                        .offset(x: highlightRect.minX - 2.5, y: highlightRect.minY + safeArea.top - 2.5)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    if currentHighlight >= highlightOrder.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showView = false
                        }
                        onFinished()
                    } else {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                            showTitle = false
                            currentHighlight += 1
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52){
                            showTitle = true
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        showTitle = true
                    }
                }
            
            Rectangle()
                .foregroundStyle(.clear)
            /// Adding Border
            /// Simply Extends its size
                .frame(width: highlightRect.width + 20, height: highlightRect.height + 20)
                .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius, style: highlight.style))
                .popover(isPresented: $showTitle) {
                    Text(highlight.title)
                        .padding(.horizontal, 10)
                        .presentationCompactAdaptation(.popover)
                        .interactiveDismissDisabled()
                }
                .scaleEffect(highlight.scale)
                .offset(x: highlightRect.minX - 10, y: highlightRect.minY - 10)
        }
    }
}

extension View {
    @ViewBuilder
    func reverseMask<Content: View>(alignment: Alignment = .topLeading, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .mask {
                Rectangle()
                    .overlay(alignment: alignment){
                        content()
                            .blendMode(.destinationOut)
                    }
            }
    }
}



///Anchor Key
fileprivate struct HighlightAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Highlight] = [:]
    
    static func reduce(value: inout [Int : Highlight], nextValue: () -> [Int : Highlight]) {
        value.merge(nextValue()) { $1 }
    }
}

#Preview {
    ContentView()
}
