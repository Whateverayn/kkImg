//
//  InspectorTabBar.swift
//  kkImg
//
//  Created by W on R 8/03/01.
//

import SwiftUI

struct InspectorTabBar: NSViewRepresentable {
    @Binding var selection: InspectorTab
    let items: [InspectorTab]
    
    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = items.count
        control.segmentStyle = .separated
        control.cell?.isBordered = false
        control.trackingMode = .selectOne
        control.focusRingType = .none
        
        for (index, item) in items.enumerated() {
            control.setImage(NSImage(systemSymbolName: item.iconName, accessibilityDescription: item.id), forSegment: index)
            control.setWidth(32, forSegment: index)
        }
        
        control.target = context.coordinator
        control.action = #selector(Coordinator.valueChanged(_:))
        return control
    }
    
    func updateNSView(_ nsView: NSSegmentedControl, context: Context) {
        // 現在の選択インデックスを特定
        guard let selectedIndex = items.firstIndex(of: selection) else { return }
        nsView.selectedSegment = selectedIndex
        
        // 全セグメントのアイコンを再設定
        for (index, item) in items.enumerated() {
            let iconName = (index == selectedIndex) ? "\(item.iconName).fill" : item.iconName
            let image = NSImage(systemSymbolName: iconName, accessibilityDescription: item.displayName)
            nsView.setImage(image, forSegment: index)
            nsView.setWidth(32, forSegment: index)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject {
        var parent: InspectorTabBar
        init(_ parent: InspectorTabBar) { self.parent = parent }
        @objc func valueChanged(_ sender: NSSegmentedControl) {
            parent.selection = parent.items[sender.selectedSegment]
        }
    }
}

#Preview {
    InspectorTabBar(selection: .constant(.file), items: InspectorTab.allCases)
}
