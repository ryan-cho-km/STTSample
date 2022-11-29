//
/******************************************************************************
 * Copyright (c) 2022 KineMaster Corp. All rights reserved.
 * https://www.kinemastercorp.com/
 *
 * THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
 * PURPOSE.
 ******************************************************************************/

import SwiftUI

struct ContentView: View {
    
    @StateObject var speechRecognizer = SpeechRecognizer()
    
    @State private var isFileImporterPresented: Bool = false
    
    @State var file: File?
    @State var language: Language = .english
    
    @State var transcript: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "square.and.arrow.down.on.square")
                    Text("파일 가져오기")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFileImporterPresented = true
                }
                .padding()
                .frame(
                    width: 300,
                    height: 40
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                )
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.audio]) { result in
                        guard let url = try? result.get() else {
                            return
                        }
                        file = .init(url: url)
                    }
                
                HStack {
                    Text("File : \(file?.name ?? "Empty")")
                        .bold()
                        .frame(height: 30)
                    
                    if file != nil {
                        Image(systemName: "delete.backward")
                            .renderingMode(.template)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                file = nil
                                speechRecognizer.reset()
                                transcript = ""
                            }
                    }
                    
                    Spacer()
                    
                    if file != nil {
                        Button(action: {
                            guard let fileURL = file?.url else { return }
                            Task {
                                try? await speechRecognizer.transcribeFile(
                                    url: fileURL,
                                    locale: language.locale
                                )
                            }
                        }) {
                            Text("자막 생성")
                        }
                    }
                }
                
                List {
                    Picker("언어 설정", selection: $language) {
                        ForEach(Language.allCases) { language in
                            Text(language.rawValue)
                        }
                    }
                }
                .frame(height: 120)
                
                Text("Transcript")
                    .bold()
                
                TextEditor(text: $speechRecognizer.report.transcript)
                    .frame(width: 300, height: 300)
                    .border(.black)
                    .disabled(true)
                
                Text("Report")
                    .bold()
                    .padding(.bottom, 8)
                
                VStack(spacing: 16) {
                    Text("총 소요시간: \(speechRecognizer.report.responseTime) 초")
                        .padding(.top, 8)
                    
                    Divider()
                    
                    HStack {
                        Text("찾은 문장")
                            .frame(maxWidth: .infinity)
                        Text("시작 시간")
                            .frame(maxWidth: .infinity)
                        Text("끝난 시간")
                            .frame(maxWidth: .infinity)
                    }
                    
                    ForEach(speechRecognizer.report.sentences) { sentence in
                        HStack {
                            Text(sentence.text)
                                .frame(maxWidth: .infinity)
                            Text("\(sentence.startTime) 초")
                                .frame(maxWidth: .infinity)
                            Text("\(sentence.endTime) 초")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .border(.black)
            }
            .frame(maxWidth: 300, maxHeight: .infinity)
        }
    }
}

struct File {
    let url: URL
    let name: String
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
}

enum Language: String, CaseIterable, Identifiable {
    case english = "영어"
    case korean = "한국어"
    var id: Self { self }
    
    var locale: Locale {
        switch self {
        case .english:
            return .init(identifier: "en-us")
        case .korean:
            return .init(identifier: "ko-kr")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
