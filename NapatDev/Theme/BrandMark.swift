import SwiftUI

struct BrandMark: View {
    let seed: String
    var size: CGFloat = 32
    var radius: CGFloat = 8

    var body: some View {
        let spec = BrandRegistry.spec(for: seed)
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(spec.color)
            .frame(width: size, height: size)
            .overlay(
                spec.glyph(size)
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

struct BrandSpec {
    let color: Color
    let glyph: (CGFloat) -> AnyView
}

enum BrandRegistry {
    static let all: [String] = [
        "lumen", "pivot", "nimbus", "ember", "orbit", "harbor",
        "fern", "slab", "meridian", "vellum", "codex", "delta",
        "quill", "basin"
    ]

    static func spec(for seed: String) -> BrandSpec {
        switch seed {
        case "lumen":    return .init(color: Color(hex: 0xF5A524), glyph: lumen)
        case "pivot":    return .init(color: Color(hex: 0x111827), glyph: pivot)
        case "nimbus":   return .init(color: Color(hex: 0x3B82F6), glyph: nimbus)
        case "ember":    return .init(color: Color(hex: 0xE11D48), glyph: ember)
        case "orbit":    return .init(color: Color(hex: 0x8B5CF6), glyph: orbit)
        case "harbor":   return .init(color: Color(hex: 0x0EA5E9), glyph: harbor)
        case "fern":     return .init(color: Color(hex: 0x16A34A), glyph: fern)
        case "slab":     return .init(color: Color(hex: 0x111827), glyph: slab)
        case "meridian": return .init(color: Color(hex: 0x4F46E5), glyph: meridian)
        case "vellum":   return .init(color: Color(hex: 0xD97706), glyph: vellum)
        case "codex":    return .init(color: Color(hex: 0x0F172A), glyph: codex)
        case "delta":    return .init(color: Color(hex: 0x14B8A6), glyph: delta)
        case "quill":    return .init(color: Color(hex: 0xBE185D), glyph: quill)
        case "basin":    return .init(color: Color(hex: 0x2563EB), glyph: basin)
        default:         return .init(color: Color(hex: 0x64748B), glyph: defaultMark)
        }
    }

    // MARK: - Glyphs (all SwiftUI paths, mirrored from icons.jsx SVGs)

    private static func lumen(_ s: CGFloat) -> AnyView {
        AnyView(
            ZStack {
                Circle().frame(width: s * 0.22, height: s * 0.22)
                ForEach(0..<6) { i in
                    RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                        .frame(width: s * 0.06, height: s * 0.14)
                        .offset(y: -s * 0.18)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
            }
        )
    }

    private static func pivot(_ s: CGFloat) -> AnyView {
        AnyView(
            HStack(spacing: s * 0.04) {
                RoundedRectangle(cornerRadius: 1.5).frame(width: s * 0.15, height: s * 0.35)
                VStack(spacing: s * 0.05) {
                    RoundedRectangle(cornerRadius: 1.5).frame(width: s * 0.15, height: s * 0.15)
                    Spacer().frame(height: 0)
                }
            }
        )
    }

    private static func nimbus(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "cloud.fill").font(.system(size: s * 0.5, weight: .bold))
        )
    }

    private static func ember(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "flame.fill").font(.system(size: s * 0.5))
        )
    }

    private static func orbit(_ s: CGFloat) -> AnyView {
        AnyView(
            ZStack {
                Ellipse().stroke(lineWidth: 1.5).frame(width: s * 0.55, height: s * 0.22)
                Circle().frame(width: s * 0.18, height: s * 0.18)
            }
        )
    }

    private static func harbor(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "water.waves").font(.system(size: s * 0.5, weight: .bold))
        )
    }

    private static func fern(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "leaf.fill").font(.system(size: s * 0.5))
        )
    }

    private static func slab(_ s: CGFloat) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: s * 0.06) {
                Rectangle().frame(width: s * 0.55, height: s * 0.1)
                Rectangle().frame(width: s * 0.35, height: s * 0.1)
            }
        )
    }

    private static func meridian(_ s: CGFloat) -> AnyView {
        AnyView(
            ZStack {
                Circle().stroke(lineWidth: 1.6).frame(width: s * 0.5, height: s * 0.5)
                Rectangle().frame(width: s * 0.5, height: 1.4)
                Rectangle().frame(width: 1.4, height: s * 0.5)
            }
        )
    }

    private static func vellum(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "doc.fill").font(.system(size: s * 0.5))
        )
    }

    private static func codex(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: s * 0.45, weight: .bold))
        )
    }

    private static func delta(_ s: CGFloat) -> AnyView {
        AnyView(
            Triangle().frame(width: s * 0.5, height: s * 0.45)
        )
    }

    private static func quill(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "pencil.tip").font(.system(size: s * 0.5, weight: .bold))
        )
    }

    private static func basin(_ s: CGFloat) -> AnyView {
        AnyView(
            Image(systemName: "shield.lefthalf.filled").font(.system(size: s * 0.5))
        )
    }

    private static func defaultMark(_ s: CGFloat) -> AnyView {
        AnyView(Circle().frame(width: s * 0.3, height: s * 0.3))
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(48)), count: 5), spacing: 12) {
        ForEach(BrandRegistry.all, id: \.self) { seed in
            BrandMark(seed: seed, size: 40, radius: 10)
        }
    }
    .padding()
}
