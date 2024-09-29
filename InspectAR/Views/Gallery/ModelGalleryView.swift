//
//  ModelGalleryView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

struct ModelGridView: View {
    @State private var models: [(name: String, image: UIImage)] = []
    @State private var navigateToDetail: String? = nil
    @State private var showAddNew = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(models, id: \.name) { model in
                        ModelCell(name: model.name, image: model.image)
                            .onTapGesture {
                                navigateToDetail = model.name
                            }
                    }
                    
                    AddNewCell()
                        .onTapGesture {
                            showAddNew = true
                        }
                }
                .padding()
            }
            .navigationTitle("3D Models")
            .onAppear(perform: loadModels)
            .background(
                NavigationLink(destination: ModelDetailView(modelName: navigateToDetail ?? ""), tag: navigateToDetail ?? "", selection: $navigateToDetail) {
                    EmptyView()
                }
            )
            .sheet(isPresented: $showAddNew) {
                AddNewModelView()
            }
        }
    }
    
    private func loadModels() {
        // This is where you would use FileArchive to load the models
        // For this example, we'll use mock data
        models = [
            (name: "Cube", image: UIImage(systemName: "cube")!),
            (name: "Sphere", image: UIImage(systemName: "circle.fill")!),
            (name: "Pyramid", image: UIImage(systemName: "triangle")!)
        ]
    }
}

struct ModelCell: View {
    let name: String
    let image: UIImage
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Text(name)
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AddNewCell: View {
    var body: some View {
        VStack {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            Text("Add new")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .frame(width: 100, height: 100)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ModelDetailView: View {
    let modelName: String
    
    var body: some View {
        Text("Detail view for \(modelName)")
            .navigationTitle(modelName)
    }
}

struct AddNewModelView: View {
    var body: some View {
        Text("Add new model view")
            .navigationTitle("Add New Model")
    }
}

struct ModelGridView_Previews: PreviewProvider {
    static var previews: some View {
        ModelGridView()
    }
}



//import SwiftUI
//import SceneKit
//
//struct Cool3DModelGridView: View {
//    @State private var models: [Model] = []
//    @State private var selectedModel: Model?
//    @State private var showAddNew = false
//    @State private var isLoading = true
//    
//    private let columns = [
//        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
//    ]
//    
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//            
//            ScrollView {
//                LazyVGrid(columns: columns, spacing: 20) {
//                    ForEach(models) { model in
//                        ModelCell(model: model)
//                            .onTapGesture {
//                                withAnimation(.spring()) {
//                                    selectedModel = model
//                                }
//                            }
//                    }
//                    
//                    AddNewCell()
//                        .onTapGesture {
//                            showAddNew = true
//                        }
//                }
//                .padding()
//            }
//            .navigationTitle("3D Models")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: { /* Implement settings action */ }) {
//                        Image(systemName: "gear")
//                            .foregroundColor(.white)
//                    }
//                }
//            }
//            
//            if isLoading {
//                LoadingView()
//            }
//        }
//        .sheet(item: $selectedModel) { model in
//            ModelDetailView(model: model)
//        }
//        .sheet(isPresented: $showAddNew) {
//            AddNewModelView()
//        }
//        .onAppear(perform: loadModels)
//    }
//    
//    private func loadModels() {
//        // Simulating network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            // Step 1: Create SCNNode for each model
//            let sphereNode = SCNNode(geometry: SCNSphere(radius: 1.0))
//            let cubeNode = SCNNode(geometry: SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0))
//            let torusNode = SCNNode(geometry: SCNTorus(ringRadius: 1.0, pipeRadius: 0.3))
//            
//            // Step 2: Create SCNScene for each model and add the corresponding node
//            let sphereScene = SCNScene()
//            sphereScene.rootNode.addChildNode(sphereNode)
//            
//            let cubeScene = SCNScene()
//            cubeScene.rootNode.addChildNode(cubeNode)
//            
//            let torusScene = SCNScene()
//            torusScene.rootNode.addChildNode(torusNode)
//            
//            // Step 3: Assign these scenes to the models array
//            models = [
//                Model(name: "Sphere", scnScene: sphereScene),
//                Model(name: "Cube", scnScene: cubeScene),
//                Model(name: "Torus", scnScene: torusScene)
//                // Add more models as needed
//            ]
//            isLoading = false
//        }
//    }
//}
//
//struct Model: Identifiable {
//    let id = UUID()
//    let name: String
//    let scnScene: SCNScene
//}
//
//struct ModelCell: View {
//    let model: Model
//    @State private var rotation: Double = 0
//    
//    var body: some View {
//        VStack {
//            SceneView(
//                scene: model.scnScene,
//                options: [.autoenablesDefaultLighting, .allowsCameraControl]
//            )
//            .frame(width: 150, height: 150)
//            .clipShape(RoundedRectangle(cornerRadius: 20))
////            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
//            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
//            .onAppear {
//                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
//                    rotation = 360
//                }
//            }
//            
//            Text(model.name)
//                .font(.headline)
//                .foregroundColor(.white)
//        }
//        .padding()
//        .background(Color.gray.opacity(0.2))
//        .cornerRadius(25)
//    }
//}
//
//struct AddNewCell: View {
//    var body: some View {
//        VStack {
//            ZStack {
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                    .frame(width: 150, height: 150)
//                
//                Image(systemName: "plus")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 50, height: 50)
//                    .foregroundColor(.white)
//            }
//            
//            Text("Add New")
//                .font(.headline)
//                .foregroundColor(.white)
//        }
//        .padding()
//        .background(Color.gray.opacity(0.2))
//        .cornerRadius(25)
//    }
//}
//
//struct ModelDetailView: View {
//    let model: Model
//    
//    var body: some View {
//        VStack {
//            SceneView(
//                scene: model.scnScene,
//                options: [.autoenablesDefaultLighting, .allowsCameraControl]
//            )
//            .frame(height: 300)
//            
//            Text(model.name)
//                .font(.largeTitle)
//                .padding()
//            
//            // Add more details and interactions here
//        }
//        .navigationTitle(model.name)
//    }
//}
//
//struct AddNewModelView: View {
//    var body: some View {
//        Text("Add new model view")
//            .navigationTitle("Add New Model")
//    }
//}
//
//struct LoadingView: View {
//    @State private var isAnimating = false
//    
//    var body: some View {
//        Circle()
//            .trim(from: 0, to: 0.7)
//            .stroke(Color.white, lineWidth: 5)
//            .frame(width: 50, height: 50)
//            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
//            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
//            .onAppear {
//                isAnimating = true
//            }
//    }
//}
//
//struct Cool3DModelGridView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            Cool3DModelGridView()
//        }
//        .preferredColorScheme(.dark)
//    }
//}
