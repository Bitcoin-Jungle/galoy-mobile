import WidgetKit
import SwiftUI

struct pricewidget: Widget {
    let kind: String = "pricewidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BitcoinPriceProvider()) { entry in
            BitcoinPriceView(entry: entry)
        }
        .configurationDisplayName("Bitcoin Price")
        .description("Displays the current price of bitcoin.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BitcoinPriceEntry: TimelineEntry {
    let date: Date
    let price: Double
}

struct BitcoinPriceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BitcoinPriceEntry {
        BitcoinPriceEntry(date: Date(), price: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BitcoinPriceEntry) -> ()) {
        let entry = BitcoinPriceEntry(date: Date(), price: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BitcoinPriceEntry>) -> ()) {
        let currentDate = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let url = URL(string: "https://orders.bitcoinjungle.app/price")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                let timeline = Timeline(entries: [BitcoinPriceEntry(date: currentDate, price: 0)], policy: .atEnd)
                completion(timeline)
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys

            if let response = try? decoder.decode(BitcoinJungleResponse.self, from: data) {
                let price = Double(response.BTCUSD)
                let entry = BitcoinPriceEntry(date: currentDate, price: price!)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
                completion(timeline)
            } else {
                let timeline = Timeline(entries: [BitcoinPriceEntry(date: currentDate, price: 0)], policy: .atEnd)
                completion(timeline)
            }
        }.resume()
    }
}

struct BitcoinPriceView: View {
    let entry: BitcoinPriceProvider.Entry

    var body: some View {
        VStack {
            Text("Bitcoin Price")
                .font(.headline)
            Text("$\(entry.price, specifier: "%.2f")")
                .font(.title)
        }
    }
}

struct BitcoinJungleResponse: Codable {
    let BTCUSD: String
    let BTCCRC: Int
    let USDCRC: Double
    let USDCAD: Double
    let timestamp: String
}

struct BitcoinPriceIndex: Codable {
    let USD: BitcoinPrice
}

struct BitcoinPrice: Codable {
    let rateFloat: Double
}