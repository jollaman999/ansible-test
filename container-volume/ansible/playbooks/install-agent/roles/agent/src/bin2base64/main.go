package main

import (
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

const (
	chunkSize        = 1024 * 1024
	base64LineLength = 100000
	filePermissions  = 0755
)

func splitString(s string, size int) ([]string, error) {
	if size <= 0 {
		return nil, fmt.Errorf("invalid chunk size: %d", size)
	}

	var chunks []string
	runes := []rune(s)

	for i := 0; i < len(runes); i += size {
		end := i + size
		if end > len(runes) {
			end = len(runes)
		}
		chunks = append(chunks, string(runes[i:end]))
	}
	return chunks, nil
}

func writeScriptContent(outFile *os.File, inputFile *os.File, executableName string) error {
	if _, err := outFile.WriteString("#!/bin/bash\n\n"); err != nil {
		return fmt.Errorf("failed to write shebang: %v", err)
	}

	if _, err :=outFile.WriteString("cd\n\n"); err != nil {
		return fmt.Errorf("failed to write cd command: %v", err)
	}

	buffer := make([]byte, chunkSize)
	isFirst := true

	
	for {
		n, err := inputFile.Read(buffer)
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to read input file: %v", err)
		}

		encoded := base64.StdEncoding.EncodeToString(buffer[:n])
		chunks, err := splitString(encoded, base64LineLength)
		if err != nil {
			return fmt.Errorf("failed to split base64 string: %v", err)
		}

		for _, chunk := range chunks {
			var err error
			if isFirst {
				_, err = fmt.Fprintf(outFile, "echo \"%s\" | base64 -d > %s\n", chunk, executableName)
				isFirst = false
			} else {
				_, err = fmt.Fprintf(outFile, "echo \"%s\" | base64 -d >> %s\n", chunk, executableName)
			}
			if err != nil {
				return fmt.Errorf("failed to write to output file: %v", err)
			}
		}
	}

	return nil
}

func main() {
	inputFile := flag.String("input", "", "Input executable file path")
	executableName := flag.String("name", "binary", "Output executable name")
	outputScript := flag.String("output", "run.sh", "Output script name")
	flag.Parse()

	execPath, err := os.Executable()
    if err != nil {
        fmt.Println(err)
        os.Exit(1)
    }

	if *inputFile == "" {
		fmt.Println("Usage: " + filepath.Base(execPath) + " -input <executable_path> [-name <executable_name>] [-output <script_name>]")
		os.Exit(1)
	}

	if _, err := os.Stat(*inputFile); os.IsNotExist(err) {
		fmt.Printf("Input file does not exist: %s\n", *inputFile)
		os.Exit(1)
	}

	inFile, err := os.Open(*inputFile)
	if err != nil {
		fmt.Printf("Cannot open input file: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		_ = inFile.Close()
	}()

	outFile, err := os.OpenFile(*outputScript, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, filePermissions)
	if err != nil {
		fmt.Printf("Cannot create output file: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		_ = outFile.Close()
	}()

	if err := writeScriptContent(outFile, inFile, *executableName); err != nil {
		fmt.Printf("Error generating script: %v\n", err)
		_ = os.Remove(*outputScript)
		os.Exit(1)
	}

	fmt.Printf("Script generated successfully: %s\n", *outputScript)
}
