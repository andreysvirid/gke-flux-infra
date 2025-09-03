package main

import (
	"log"
	"math/rand"
	"os"
	"strconv"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

func main() {
	token := os.Getenv("TELEGRAM_TOKEN")
	if token == "" {
		log.Fatal("No TELEGRAM_TOKEN provided")
	}

	bot, err := tgbotapi.NewBotAPI(token)
	if err != nil {
		log.Panic(err)
	}

	log.Printf("Authorized on account %s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates := bot.GetUpdatesChan(u)

	rand.Seed(time.Now().UnixNano())

	for update := range updates {
		if update.Message == nil {
			continue
		}

		roll := rand.Intn(6) + 1
		text := "🎲 Ви кинули кості: " + strconv.Itoa(roll)

		msg := tgbotapi.NewMessage(update.Message.Chat.ID, text)
		_, err := bot.Send(msg)
		if err != nil {
			log.Println("Failed to send message:", err)
		}
	}
}
