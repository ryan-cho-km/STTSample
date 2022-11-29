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
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: R.image.import)
                    Text(R.string.importFile)
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
                    Text(String(format: R.string.file, file?.name ?? "Empty"))
                        .bold()
                        .frame(height: 30)
                    
                    if file != nil {
                        Image(systemName: R.image.delete)
                            .renderingMode(.template)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                file = nil
                                speechRecognizer.reset()
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
                            Text(R.string.createSubTitle)
                        }
                    }
                }
                
                List {
                    Picker(R.string.setLanguage, selection: $language) {
                        ForEach(Language.allCases) { language in
                            Text(language.rawValue)
                        }
                    }
                }
                .frame(height: 120)
                
                Text(R.string.transcript)
                    .bold()
                
                TextEditor(text: $speechRecognizer.report.transcript)
                    .frame(width: 300, height: 300)
                    .border(.black)
                    .disabled(true)
                
                Text(R.string.report)
                    .bold()
                    .padding(.bottom, 8)
                
                VStack(spacing: 16) {
                    Text(String(format: R.string.totalDuration, speechRecognizer.report.responseTime))
                        .padding(.top, 8)
                    
                    Divider()
                    
                    HStack {
                        Text(R.string.findSentence)
                            .frame(maxWidth: .infinity)
                        Text(R.string.startTime)
                            .frame(maxWidth: .infinity)
                        Text(R.string.endTime)
                            .frame(maxWidth: .infinity)
                    }
                    
                    ForEach(speechRecognizer.report.sentences) { sentence in
                        HStack {
                            Text(sentence.text)
                                .frame(maxWidth: .infinity)
                            Text(String(format: R.string.duration, sentence.startTime))
                                .frame(maxWidth: .infinity)
                            Text(String(format: R.string.duration, sentence.endTime))
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

fileprivate struct R {
    struct image {
        static let `import` = "square.and.arrow.down.on.square"
        static let delete = "delete.backward"
    }
    
    struct string {
        static let importFile = "파일 가져오기"
        static let file = "File : %@"
        static let createSubTitle = "자막 생성"
        static let setLanguage = "언어 설정"
        static let transcript = "Transcript"
        static let report = "Report"
        static let totalDuration = "총 소요시간: %d초"
        static let findSentence = "찾은 문장"
        static let startTime = "시작 시간"
        static let endTime = "끝난 시간"
        static let duration = "%d 초"
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
