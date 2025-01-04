//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

@available(macOS 14.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct HTTPSDecryptionPage: View {
  typealias Data = Profile.PersistentModel

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var presentingEditor = false
  @State private var presentingFileExporter = false
  @Query(sort: \Data.creationDate) private var profiles: [Data]

  private var profile: Data {
    profiles.first ?? Data()
  }
  private let certbot = Certbot()

  var body: some View {
    VStack(alignment: .leading) {
      CapabilitiesToggle(option: .httpsDecryption) {
        Text("HTTP Decryption")
          .font(.largeTitle)
          .bold()
      }
      .toggleStyle(.switch)

      Text(
        "Decrypt HTTPS traffic with man-in-the-middle (MitM) attack."
      )
      .font(.footnote)
      .foregroundColor(.secondary)
      .padding(.bottom)

      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          Section {
            CertificateGroup(certbot: certbot)
              .padding(.bottom)

            ActionsGroup(certbot: certbot)
          } header: {
            Text("CA Certificate")
              .textCase(.uppercase)
              .font(.headline)
              .foregroundColor(.yellow)
            Divider()
          }

          OptionsGroup(data: profile)
        }
        .padding(.trailing)

        VStack(alignment: .leading) {
          @Bindable var profile = profile
          Literals($profile.hostnames)
            .title("MitM Hostnames")
            .prompt(
              """
              Wildcard characters * and ? are supported.
              Use prefix - to exclude a hostname.
              By default only the requests to port 443 will be decrypted.
              • Use suffix :port to allow other ports.
              • Use suffix :0 to allow all ports.
              See manual for more information.
              """
            )
            .navigationTitle("New Hostname")

          Text(
            """
            Netbot will only decrypt traffic to the hosts whitch are declared here.
            Wildcard chanracters are allowed.
            Some applications has a strict security policy to use pinned certificates or CA. Enabling decryption to these hosts may cause problems.
            """
          )
          .font(.footnote)
          .foregroundColor(.secondary)
        }
      }
      .task {
        do {
          guard !profile.base64EncodedP12String.isEmpty else {
            return
          }
          try await certbot.loadFromBase64EncodedP12String(
            profile.base64EncodedP12String,
            passphrase: profile.passphrase
          )
        } catch {
          assertionFailure(error.localizedDescription)
        }
      }
      .onChange(of: certbot.passphrase) { _, newValue in
        guard profile.passphrase != newValue else {
          return
        }
        profile.passphrase = newValue
        Task.detached(priority: .background) {
          try await profileAssistant.replace(\.passphrase, with: newValue)
        }
      }
      .onChange(of: certbot.base64EncodedP12String) { _, newValue in
        guard profile.base64EncodedP12String != newValue else {
          return
        }
        profile.base64EncodedP12String = newValue
        Task.detached(priority: .background) {
          try await profileAssistant.replace(\.base64EncodedP12String, with: newValue)
        }
      }
      .onChange(of: profile.skipCertificateVerification) { _, newValue in
        Task.detached(priority: .background) {
          try await profileAssistant.replace(\.skipCertificateVerification, with: newValue)
        }
      }
      .onChange(of: profile.hostnames) { _, newValue in
        Task.detached(priority: .background) {
          try await profileAssistant.replace(\.hostnames, with: newValue)
        }
      }
    }
    .padding()
  }

  private struct OptionsGroup: View {
    @Bindable var data: Profile.PersistentModel

    var body: some View {
      Section {
        Toggle(
          "Skip Server Certificate Verification",
          isOn: $data.skipCertificateVerification
        )
        Text("Allow connections even if the remote server uses an invalid certificate.")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.leading)

        Toggle("Perform MitM on TCP Connections", isOn: .constant(false))
        Text(
          "By default, only HTTPS connections which use HTTP proxy service will be decrypted. Enable the option to perform MitM for virtual interface connections in Enhanced Mode and connections via SOCKS5 services."
        )
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.leading)

        Toggle("MitM over HTTP/2", isOn: .constant(false))
        Text(
          "Decrypt HTTPS traffic with MitM over HTTP/2 protocol, whitch can improve the performance of concurrent requests."
        )
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.leading)
      } header: {
        Text("Options")
          .textCase(.uppercase)
          .font(.headline)
          .foregroundColor(.green)
          .padding(.top, 16)
        Divider()
      }
    }
  }

  private struct CertificateGroup: View {
    let certbot: Certbot

    var body: some View {
      HStack {
        Image(.certLargeRoot)
          .resizable()
          .frame(width: 65, height: 55)

        VStack(alignment: .leading, spacing: 8) {
          if let commonName = certbot.commonName {
            Text(commonName)
          } else {
            Text("NO CA Certificate Configured")
          }
          HStack(spacing: 4) {
            Image(systemName: certbot.isTrusted ? "plus" : "xmark")
              .symbolVariant(.circle.fill)
              .font(.footnote)
              .foregroundColor(certbot.isTrusted ? .mayaBlue : .red)
            Text(
              certbot.isTrusted
                ? "This certificate is marked as trusted" : "This certificate is not trusted"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  private struct ActionsGroup: View {
    let certbot: Certbot

    var body: some View {
      HStack(alignment: .top) {
        Text("Actions:")
        LazyVStack(alignment: .leading) {
          CertificateGenerationButton {
            Task {
              try await certbot.generate()
            }
          }

          Button {
            Task {
              try await certbot.trustLoadedCertificate()
            }
          } label: {
            Text("Install to System")
              .frame(maxWidth: .infinity)
          }
          .disabled(certbot.certificate == nil || certbot.isTrusted)

          PickSSLPKCS12BundleButton { fileURL, passphrase in
            Task {
              try await certbot.loadFromP12File(at: fileURL, passphrase: passphrase)
            }
          } label: {
            Text("Import from PKCS #12 File")
              .frame(maxWidth: .infinity)
          }

          Button {

          } label: {
            Text("Export for iOS Simulator")
              .frame(maxWidth: .infinity)
          }
          .disabled(certbot.certificate == nil)
          //        .fileExporter(isPresented: <#T##Binding<Bool>#>, documents: <#T##Collection#>, contentType: <#T##UTType#>, onCompletion: <#T##(Result<[URL], Error>) -> Void##(Result<[URL], Error>) -> Void##(_ result: Result<[URL], Error>) -> Void#>)
        }
        .frame(maxWidth: 250)
      }
    }
  }

  private struct CertificateGenerationButton: View {
    @State private var presentingGenerateAlert = false
    let action: () -> Void

    var body: some View {
      Button {
        presentingGenerateAlert = true
      } label: {
        Text("Generate New Certificate")
          .frame(maxWidth: .infinity)
      }
      .alert("Generate New Certificate", isPresented: $presentingGenerateAlert) {
        Button("Cancel", role: .cancel) {
          presentingGenerateAlert = false
        }

        Button {
          action()
        } label: {
          Text("Continue")
        }
      } message: {
        Text("Generating a new certificate will overwrite the existing one. Are you sure?")
      }
    }
  }
}

#if DEBUG
  @available(macOS 14.0, *)
  @available(iOS, unavailable)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  #Preview {
    NavigationStack {
      #if os(macOS)
        HTTPSDecryptionPage()
          .frame(width: 650, height: 510)
      #endif
    }
  }
#endif
