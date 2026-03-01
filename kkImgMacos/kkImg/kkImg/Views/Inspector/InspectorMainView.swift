//
//  InspectorMainView.swift
//  kkImg
//
//  Created by W on R 8/03/02.
//

import SwiftUI

struct InspectorMainView: View {
    @Binding var selection: InspectorTab
    @Binding var isPresented: Bool
    var body: some View {
        VStack (spacing: 0){
            Divider()
            HStack{
                Spacer()
                InspectorTabBar(selection: $selection, items: InspectorTab.allCases)
                    .fixedSize()
                Spacer()
            }
            .padding(.top, 3)
            .padding(.bottom, 2)
            Divider()
            
            ScrollView{
                VStack(alignment: .leading) {
                    switch selection {
                    case .file:
                        Text("File")
                    case .filters:
                        Text("Filter")
                    case .actions:
                        Text("Actions")
                    case .activity:
                        Text("Activity")
                    }
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(){
                Spacer()
                Button {
                    isPresented.toggle()
                } label: {
                    Label(isPresented ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
                }
                .help("Hide or show the Inspector")
            }
        }
    }
}

#Preview {
    InspectorMainView(
        selection: .constant(.file),
        isPresented: .constant(true)
    )
}
