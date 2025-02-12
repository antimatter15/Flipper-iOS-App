import Core
import SwiftUI
import Peripheral

struct FileManagerView: View {
    @StateObject var viewModel: FileManagerViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            switch viewModel.content {
            case .list(let elements): listView(with: elements)
            case .file: editorView()
            case .create: createView()
            case .error(let error): Text(error)
            case .forceDelete: forceDeleteView()
            case .none: ProgressView()
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.path.isEmpty, case .list = viewModel.content {
                Menu {
                    Button {
                        viewModel.newElement(isDirectory: false)
                    } label: {
                        Text("File")
                    }

                    Button {
                        viewModel.newElement(isDirectory: true)
                    } label: {
                        Text("Folder")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            viewModel.update()
        }
    }

    func listView(with elements: [Element]) -> some View {
        List {
            if !viewModel.path.isEmpty {
                Button("..") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.primary)
            }
            if !elements.isEmpty {
                list(with: elements)
            }
        }
    }

    func list(with elements: [Element]) -> some View {
        ForEach(elements, id: \.description) {
            switch $0 {
            case .directory(let directory):
                HStack {
                    Image(systemName: "folder.fill")
                        .frame(width: 20)

                    NavigationLink(directory.name) {
                        FileManagerView(viewModel: .init(
                            path: viewModel.path.appending(directory.name),
                            mode: .list))
                    }
                    .foregroundColor(.primary)
                }
            case .file(let file):
                if let data = file.data, !data.isEmpty {
                    Text(String(decoding: data, as: UTF8.self))
                } else {
                    HStack {
                        if viewModel.canRead(file) {
                            Image(systemName: "doc")
                                .frame(width: 20)
                            NavigationLink {
                                FileManagerView(viewModel: .init(
                                    path: viewModel.path.appending(file.name),
                                    mode: .edit))
                            } label: {
                                FileRow(file: file)
                            }
                            .foregroundColor(.primary)
                        } else {
                            Image(systemName: "lock.doc")
                                .frame(width: 20)
                            FileRow(file: file)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onDelete { indexSet in
            if let index = indexSet.first {
                viewModel.delete(at: index)
            }
        }
    }

    func editorView() -> some View {
        VStack {
            TextEditor(text: $viewModel.text)
                .padding(.top, 5)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary, lineWidth: 1))

            HStack {
                Spacer()
                RoundedButton("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                RoundedButton("Save") {
                    viewModel.save()
                }
                Spacer()
            }
        }
        .padding(.bottom, 16)
    }

    func createView() -> some View {
        VStack {
            TextField("Name", text: $viewModel.name)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.gray, lineWidth: 1))
                .padding()

            HStack {
                Spacer()
                RoundedButton("Cancel", action: viewModel.cancel)
                Spacer()
                RoundedButton("Create", action: viewModel.create)
                Spacer()
            }
        }
        .padding(16)
    }

    func forceDeleteView() -> some View {
        VStack(spacing: 50) {
            Text("The directory is not empty")
                .font(.title)
            HStack {
                Spacer()
                RoundedButton(
                    "Cancel",
                    action: viewModel.cancel)
                Spacer()
                RoundedButton(
                    "Force delete",
                    isDanger: true,
                    action: viewModel.forceDelete
                )
                Spacer()
            }
        }
    }
}

struct FileRow: View {
    let file: File

    var body: some View {
        HStack {
            Text(file.name)
            Spacer()
            Text("\(file.size) bytes")
        }
    }
}
