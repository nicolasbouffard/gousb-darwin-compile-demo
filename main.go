package main

import (
	"log"

	"github.com/google/gousb"
)

func main() {
	// Inspired by https://github.com/google/gousb/blob/master/lsusb/main.go.
	gousbCTX := gousb.NewContext()
	defer gousbCTX.Close()

	devices, err := gousbCTX.OpenDevices(func(desc *gousb.DeviceDesc) bool {
		return true
	})
	defer func() {
		for _, device := range devices {
			device.Close()
		}
	}()

	if err != nil {
		log.Fatal("Failed to list devices", err)
	}

	log.Println("Listed devices", devices)
}
