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
    
    var filteredModelItems: [ModelItem] {
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
                ForEach(filteredModelItems) { modelItem in
                    let modelSetupDestination = ModelSetupView(
                        model: modelStore.load(name: modelItem.name)
                    )
                    NavigationLink(destination: modelSetupDestination) {
                        ModelItemView(model: modelItem)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                modelStore.delete(name: modelItem.name)
                                loadModels()
                            }
                        } label: {
                            Label("Delete", systemImage: "x.circle.fill")
                        }

                    }
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
            loadModels()
        }
    }
    
    func showModelPreview(_ model: ModelItem) {
        print("Model selected: \(model.name)")
    }
    
    func addNewModel() {
        print("Add new model tapped")
    }
    
    func loadModels() {
        modelItems.removeAll()
        let modelNames = modelStore.list()
        
//        // Remove items that no longer exist in store
//        modelItems.removeAll { item in
//            !modelNames.contains(item.name)
//        }
//        
//        // Add new items that non-existing before
        for name in modelNames {
//            guard !modelItems.contains(where: { $0.name == name }) else { continue }
            
            if let model = modelStore.load(name: name) {
                let modelItem = ModelItem(name: model.name, image: model.modelImage)
                modelItems.append(modelItem)
            }
        }
    }
}

struct ModelItemView: View {
    let model: ModelItem
    
    let lineSpacing: CGFloat = 2
    
    var body: some View {
        return VStack(spacing: 8) {
            Image(uiImage: model.image ?? UIImage(systemName: "cube.transparent.fill")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .foregroundColor(.gray)
            Text(model.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .frame(height: UIFont.textHeight(font: .caption1, lineCount: 2, lineSpacing: lineSpacing))
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
    }
}

struct AddNewItem: View {
    var body: some View {
        return VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))

                Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .padding(20)
            }

            Text("Add New")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
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
