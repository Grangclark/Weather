//
//  ContentView.swift
//  Weather
//
//  Created by 長橋和敏 on 2025/02/19.
//

import SwiftUI

struct ContentView: View {
    // ユーザーが入力する都市名
    @State private var cityName: String = ""
    
    // 取得した天気データを格納する
    @State private var weatherData: WeatherResponse?
    
    // エラーメッセージや状態を表示するためのフラグ
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // ユーザーが都市名を入力するテキストフィールド
                TextField("都市名を入力（例：Tokyo）", text: $cityName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 取得ボタン
                Button(action: {
                    Task {
                        await fetchWeather()
                    }
                }) {
                    Text("天気を取得")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(cityName.trimmingCharacters(in: .whitespaces).isEmpty)
                
                if isLoading {
                    ProgressView("読み込み中...")
                }
                
                // 結果表示
                if let weatherData = weatherData {
                    VStack(spacing: 10) {
                        Text("\(weatherData.name)の天気")
                            .font(.headline)
                        Text("気温：\(weatherData.main.temp, specifier: "%.1f")℃")
                        if let description = weatherData.weather.first?.description {
                            Text("状況：\(description)")
                        }
                    }
                    .padding()
                } else if !errorMessage.isEmpty {
                    Text("エラー：\(errorMessage)")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .navigationTitle("簡易天気アプリ")
        }
    }
    
    ///  天気情報を取得する非同期メソッド
    private func fetchWeather() async {
        // 前の情報をリセット
        weatherData = nil
        errorMessage = ""
        isLoading = true
        
        // OpenWeatherMapの無料APIを例にしたURL
        // 実際には必ず自分のAPIキーに置き換えてください
        // テスト時には、必ず自分の発行したキーに置き換えてください
        let apiKey = "YOUR_API_KEY"
        let cityQuery = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityName
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityQuery)&appid=\(apiKey)&units=metric&lang=ja"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "URLが不正です"
            self.isLoading = false
            return
        }
        
        do {
            // 非同期リクエストを送信しています
            let (data, _) = try await URLSession.shared.data(from: url)
            // 受け取った生データを WeatherResponse という構造体にマッピングしています
            let decodeData = try JSONDecoder().decode(WeatherResponse.self, from: data)
            self.weatherData = decodeData
        } catch {
            self.errorMessage = "データの取得または解析に失敗しました：\(error.localizedDescription)"
        }
        self.isLoading = false
    }
}

/// APIレスポンスをデコードするためのモデル（構造体）
struct WeatherResponse: Decodable {
    let name: String           // 地域名
    let main: MainInfo         // 気温などの情報
    let weather: [WeatherInfo] // 天気の詳細（説明など）
}

struct MainInfo: Decodable {
    let temp: Double           // 気温
}

struct WeatherInfo: Decodable {
    let description: String    // 天気の説明文（例："clear sky"）
}

// プレビュー
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
