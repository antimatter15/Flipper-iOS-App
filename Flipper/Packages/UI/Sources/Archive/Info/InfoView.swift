import SwiftUI

struct InfoView: View {
    @StateObject var viewModel: InfoViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isEditMode {
                SheetEditHeader(
                    "Editing",
                    onSave: viewModel.saveChanges,
                    onCancel: viewModel.undoChanges
                )
                .padding(.bottom, 6)
            } else {
                SheetHeader("Key Info") {
                    viewModel.dismiss()
                }
                .padding(.bottom, 6)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CardView(
                        item: $viewModel.item,
                        isEditing: viewModel.isEditMode,
                        kind: .existing
                    )
                    .padding(.top, 14)
                    .padding(.horizontal, 24)

                    Button {
                        viewModel.emulate()
                    } label: {
                        HStack(spacing: 7) {
                            Spacer()
                            Image("Emulate")
                            Text("Emulate")
                            Spacer()
                        }
                        .frame(height: 47)
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .background(viewModel.isConnected ? Color.a2 : .gray)
                        .cornerRadius(30)
                    }
                    .disabled(!viewModel.isConnected)
                    .opacity(viewModel.isEditMode ? 0 : 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 20) {
                        InfoButton(image: .init("edit"), title: "Edit") {
                            viewModel.edit()
                        }
                        .foregroundColor(.primary)
                        InfoButton(image: .init("share"), title: "Share") {
                            viewModel.share()
                        }
                        .foregroundColor(.primary)
                        InfoButton(image: .init("delete"), title: "Delete") {
                            viewModel.delete()
                        }
                        .foregroundColor(.sRed)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    .opacity(viewModel.isEditMode ? 0 : 1)

                    Spacer()
                }
            }
        }
        .alert(isPresented: $viewModel.isError) {
            Alert(title: Text(viewModel.error))
        }
        .onReceive(viewModel.dismissPublisher) {
            presentationMode.wrappedValue.dismiss()
        }
        .background(Color.background)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct InfoButton: View {
    let image: Image
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                image
                    .renderingMode(.template)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
        }
    }
}
