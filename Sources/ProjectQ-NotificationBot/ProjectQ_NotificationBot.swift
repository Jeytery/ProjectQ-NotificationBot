import Foundation
import Alamofire
import ProjectQ_Components2
import TelegramBotSDK

// stateless. Initialized in first call botBody()
fileprivate var timer: Timer!

// state

    // data
fileprivate var packages = [Package]()
fileprivate var chats: [Int64: Packages] = [:]

    // flags
fileprivate var timerTicksCount = 0
fileprivate var isFirstSetup = true

func botBody(update: Update, bot: TelegramBot) {
    guard
        let message = update.message,
        let from = message.from,
        let text = message.text
    else {
        return
    }

    if isFirstSetup {
        runNotificationLoop(bot: bot, from: from)
        isFirstSetup = false
    }

    if text == "add" {
        appendPackageCommand(message: message, bot: bot, from: from)
    }

    if text.contains("rm ") {
        removePackageCommand(text: text, bot: bot, from: from, chatId: message.chat.id)
    }

    if text == "pls" {
        showPackagesCommand(bot: bot, from: from, chatId: message.chat.id)
    }
    
    if text == "hw" {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "Hello, World!"
        )
    }
    
    if text == "help" {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: """
                add - adds package and run it
                rm <index> - removes package from by index
                pls - (package list) shows a packages list
            """
        )
    }
}

fileprivate func runNotificationLoop(bot: TelegramBot, from: User) {
    print("[info] run notifcation loop")
    
    func timerTick(_ timer: Timer) {
        chats.forEach {
            chatId, packages in
            packages.forEach { package in
                
                package.tasks.forEach { task in
                    
                    task.components.forEach {
                        if let handler = $0.handler as? AppearComponentHandler, handler.shouldAppear() {
                            sendTask(bot: bot, from: from, task: task, package: package, chatId: chatId)
                        }
                    }
                }
            }
        }
    }
    
    timer = Timer.scheduledTimer(
        withTimeInterval: 1.0,
        repeats: true
    ) {
        timer in
        timerTick(timer)
    }
}

//MARK: - helpers
fileprivate func addPackage(_ package: Package, bot: TelegramBot, from: User, chatId: Int64) {
    bot.sendMessageAsync(
        chatId: .chat(from.id),
        text: "Added \(package.name)"
    )
    if chats[chatId] == nil {
        chats[chatId] = []
    }
    chats[chatId]!.append(package)
}

fileprivate func removePackage(_ index: Int, bot: TelegramBot, from: User, chatId: Int64) {
    bot.sendMessageAsync(
        chatId: .chat(chatId),
        text: "Remove at \(index)"
    )
    chats[chatId]?.remove(at: index)
}

fileprivate func sendTask(bot: TelegramBot, from: User, task: Task, package: Package, chatId: Int64) {
    let dataString = task.components.map {
        if let handler = $0.handler as? DataComponentHandler {
            return handler.data()
        }
        else {
            return ""
        }
    }.joined(separator: "\n")
    
    bot.sendMessageAsync(
        chatId: .chat(chatId),
        text: """
        from package: \(package.name)
        name: \(task.name)

        \(dataString)
        """
    )
}

// MARK: - commands
fileprivate func appendPackageCommand(message: Message, bot: TelegramBot, from: User) {
    guard let message = message.replyToMessage else {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "Use this command as a reply to package file"
        )
        return
    }

    guard let document = message.document else {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "Use this command as a reply to package file"
        )
        return
    }

    bot.getFileAsync(fileId: document.fileId) {
        file, error in
        getFileCompletion(
            file: file,
            error: error,
            bot: bot,
            from: from,
            chatId: message.chat.id
        )
    }
}

fileprivate func getFileCompletion(
    file: File?,
    error: DataTaskError?,
    bot: TelegramBot,
    from: User,
    chatId: Int64
) {
     if let error = error {
         bot.sendMessageAsync(
             chatId: .chat(from.id),
             text: error.debugDescription
         )
         return
     }

     guard let filePath = file?.filePath else {
         bot.sendMessageAsync(
             chatId: .chat(from.id),
             text: "File path is empty. Try again"
         )
         return
     }

     let url = "https://api.telegram.org/file/bot\(bot.token)/\(filePath)"
     AF.request(url, method: .get).responseData {
         response in
         switch response.result {
         case .success(let data):
             guard let codablePackage = try? JSONDecoder().decode(CodablePackage.self, from: data) else {
                 return
             }
             addPackage(codablePackage.package, bot: bot, from: from, chatId: chatId)

             break
         case .failure(let error):
             bot.sendMessageAsync(
                 chatId: .chat(from.id),
                 text: error.localizedDescription
             )
             break
         }
     }
}

fileprivate func removePackageCommand(text: String, bot: TelegramBot, from: User, chatId: Int64) {
    let array = text.split(separator: " ")
    if array.count < 1 {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "You haven't provided index. Try rm <index>, rm 1"
        )
    }

    if let index = Int(array[1]) {
        removePackage(index, bot: bot, from: from, chatId: chatId)
    }
    else {
        bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "Index must be a number. Try rm <index>, rm 1"
        )
    }
}

fileprivate func showPackagesCommand(bot: TelegramBot, from: User, chatId: Int64) {
    guard let packages = chats[chatId] else {
        return bot.sendMessageAsync(
            chatId: .chat(from.id),
            text: "No Packages"
        )
    }

    var string: String = ""
    for i in 0 ..< packages.count {
        let package = packages[i]
        string += "\(i). \(package.name) \n"
    }

    bot.sendMessageAsync(
        chatId: .chat(from.id),
        text: string
    )
}

public struct ProjectQ_NotificationBot {
    init() {
        let token = ""
        print("BOT STARTED")
        let bot = TelegramBot(token: token)
       
        while let update = bot.nextUpdateSync() {
            botBody(update: update, bot: bot)
        }
       
        fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
    }
}

let bot = ProjectQ_NotificationBot()
