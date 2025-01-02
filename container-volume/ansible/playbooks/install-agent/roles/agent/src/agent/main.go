package main

import (
	"flag"
	"fmt"
	"time"
)

var version = "1.0.0"

func main() {
	versionFlag := flag.Bool("version", false, "print version information")
	flag.Parse()

	if *versionFlag {
		fmt.Printf("Version: %s\n", version)
		return
	}

	startTime := time.Now()

	for {
		elapsed := time.Since(startTime)
		minutes := int(elapsed.Minutes())
		fmt.Printf("Hello, World! I'm ish!! (Running time: %d minutes)\n", minutes)
		time.Sleep(time.Minute)
	}
}
