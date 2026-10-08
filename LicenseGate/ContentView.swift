import SwiftUI

struct ContentView: View {
    @State private var record = LicenseStore.load()
    @State private var code = ""
    @State private var error = ""

    private var phase: Phase {
        guard let record else { return .trial }
        if record.status == "permanent" { return .done }
        if record.status == "trial", Date().timeIntervalSince1970 < record.expiresAt { return .active }
        return .renew
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("应用已解锁").font(.largeTitle.bold()).foregroundStyle(.white)
                Text(statusText)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.08, green: 0.10, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Spacer()
            }
            .padding(24)
            if phase == .trial || phase == .renew {
                gate
            }
        }
    }

    private var statusText: String {
        switch phase {
        case .done:
            return "已永久解锁，后续无需再输入验证码。"
        case .active:
            let date = Date(timeIntervalSince1970: record?.expiresAt ?? 0)
            return "试用中，到期时间：\(date.formatted(date: .abbreviated, time: .shortened))。到期后需输入 2234。"
        default:
            return "未授权"
        }
    }

    private var gate: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text("输入验证码开始使用").font(.title2.bold())
                Text(phase == .renew ? "试用已到期。输入 2234 后永久解锁，之后不再弹窗。" : "输入 1234 可使用 30 天。到期后需要 2234 永久解锁。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("验证码", text: $code)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                if !error.isEmpty { Text(error).foregroundStyle(.red).font(.footnote) }
                Button("确认") { submit() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.18, green: 0.53, blue: 1))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .background(Color(red: 0.08, green: 0.09, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(24)
        }
    }

    private func submit() {
        if phase == .trial && code.trimmingCharacters(in: .whitespaces) == "1234" {
            record = LicenseRecord(status: "trial", expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
            LicenseStore.save(record)
            error = ""
            code = ""
            return
        }
        if phase == .renew && code.trimmingCharacters(in: .whitespaces) == "2234" {
            record = LicenseRecord(status: "permanent", expiresAt: 0)
            LicenseStore.save(record)
            error = ""
            code = ""
            return
        }
        error = "验证码不正确"
    }
}

enum Phase { case trial, active, renew, done }

struct LicenseRecord: Codable {
    var status: String
    var expiresAt: TimeInterval
}

enum LicenseStore {
    private static let key = "license_gate_ios_v1"
    static func load() -> LicenseRecord? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LicenseRecord.self, from: data)
    }
    static func save(_ record: LicenseRecord?) {
        guard let record, let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
