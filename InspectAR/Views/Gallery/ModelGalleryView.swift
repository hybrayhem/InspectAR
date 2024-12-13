//
//  ModelGalleryView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

struct ModelItem: Identifiable {
    let id = UUID()
    let name: String
    let image: UIImage?
}

struct ModelGalleryView: View {
    @State private var searchText = ""
    @State private var modelItems: [ModelItem]
    private let modelStore: ModelStore
    
    init(modelItems: [ModelItem] = [], modelStore: ModelStore = ModelStore()) {
        _modelItems = State(initialValue: modelItems)
        self.modelStore = modelStore
    }
    
    var filteredModels: [ModelItem] {
        if searchText.isEmpty {
            return modelItems
        }
        return modelItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // Model items
                ForEach(filteredModels) { model in
                    let modelSetupDestination = ModelSetupView(
                        model: modelStore.load(name: model.name)
                    )
                    NavigationLink(destination: modelSetupDestination) {
                        ModelItemView(model: model)
                    }
                    .buttonStyle(.plain)
                }
                
                // Add New item
                let addNewDestination = ModelSetupView()
                NavigationLink(destination: addNewDestination) {
                    AddNewItem()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search models, .step files")
        .navigationTitle("InspectAR")
        .onAppear {
            getModels()
        }
    }
    
    func showModelPreview(_ model: ModelItem) {
        print("Model selected: \(model.name)")
    }
    
    func addNewModel() {
        print("Add new model tapped")
    }
    
    func getModels() {
        let modelNames = modelStore.list()
        
        for name in modelNames {
            guard !modelItems.contains(where: { $0.name == name }) else { continue }
            
            let model = modelStore.load(name: name)
            let modelItem = ModelItem(name: model.name, image: model.modelImage)
            modelItems.append(modelItem)
        }
    }
}

struct ModelItemView: View {
    let model: ModelItem
    
//    var action: () -> Void
    var body: some View {
        let content = VStack(spacing: 8) {
            Image(uiImage: model.image ?? UIImage(systemName: "cube.transparent.fill")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity) // maxHeight: .infinity
                .cornerRadius(10)
                .foregroundColor(.gray)
            Text(model.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        // .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
        
        return content
//        return Button(action: action) {
//            content
//        }
//        .buttonStyle(.plain)
    }
}

struct AddNewItem: View {
//    var action: () -> Void
    var body: some View {
        let content = VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    // .frame(maxWidth: .infinity)
                    // .aspectRatio(1, contentMode: .fit)

                Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .padding(20)
            }
            // .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("Add New")
                .font(.caption)
                .foregroundColor(.primary)
        }
        // .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
        
        return content
//        return Button(action: action) {
//            content
//        }
//        .buttonStyle(.plain)
    }
}

#Preview {
    let previewModels = [
        ModelItem(name: "Model 1", image: UIImage(systemName: "cube")),
        ModelItem(name: "Model 2", image: UIImage(systemName: "circle.fill")),
        ModelItem(name: "Model 3", image: UIImage(systemName: "triangle")),
        ModelItem(name: "Model 4", image: nil)
    ]
    
    let view = ModelGalleryView(modelItems: previewModels)
    
    return NavigationStack {
        view
    }
}
