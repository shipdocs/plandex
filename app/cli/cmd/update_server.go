package cmd

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"plandex-cli/term"
	"strings"

	"github.com/spf13/cobra"
)

var updateServerCmd = &cobra.Command{
	Use:   "update-server",
	Short: "Update local Plandex server to latest version",
	Long: `Update the local Plandex server installation to the latest version.
This command will:
- Pull the latest code from the repository
- Rebuild and restart Docker containers if they're running
- Ensure your local server has the latest features and bug fixes`,
	Run: updateServer,
}

func init() {
	RootCmd.AddCommand(updateServerCmd)
}

func updateServer(cmd *cobra.Command, args []string) {
	fmt.Println("🔄 Updating local Plandex server...")
	
	// Check if local server directory exists
	homeDir, err := os.UserHomeDir()
	if err != nil {
		term.OutputErrorAndExit("Could not determine home directory: %v", err)
	}
	
	serverDir := filepath.Join(homeDir, "plandex-server")
	if _, err := os.Stat(serverDir); os.IsNotExist(err) {
		term.OutputErrorAndExit("No local server installation found at %s\nRun the installer to set up local mode.", serverDir)
	}
	
	// Check if it's a git repository
	gitDir := filepath.Join(serverDir, ".git")
	if _, err := os.Stat(gitDir); os.IsNotExist(err) {
		term.OutputErrorAndExit("Local server directory is not a git repository.\nPlease reinstall using the installer.")
	}
	
	// Change to server directory
	originalDir, err := os.Getwd()
	if err != nil {
		term.OutputErrorAndExit("Could not get current directory: %v", err)
	}
	defer os.Chdir(originalDir)
	
	err = os.Chdir(serverDir)
	if err != nil {
		term.OutputErrorAndExit("Could not change to server directory: %v", err)
	}
	
	term.StartSpinner("Checking for updates...")
	
	// Fetch latest changes
	cmd_fetch := exec.Command("git", "fetch", "origin")
	cmd_fetch.Stdout = nil
	cmd_fetch.Stderr = nil
	err = cmd_fetch.Run()
	if err != nil {
		term.StopSpinner()
		term.OutputErrorAndExit("Could not fetch latest changes: %v", err)
	}
	
	// Check if update is needed
	currentCmd := exec.Command("git", "rev-parse", "HEAD")
	currentOut, err := currentCmd.Output()
	if err != nil {
		term.StopSpinner()
		term.OutputErrorAndExit("Could not get current commit: %v", err)
	}
	
	latestCmd := exec.Command("git", "rev-parse", "origin/main")
	latestOut, err := latestCmd.Output()
	if err != nil {
		term.StopSpinner()
		term.OutputErrorAndExit("Could not get latest commit: %v", err)
	}
	
	currentCommit := strings.TrimSpace(string(currentOut))
	latestCommit := strings.TrimSpace(string(latestOut))
	
	if currentCommit == latestCommit {
		term.StopSpinner()
		fmt.Println("✅ Local server is already up to date")
		return
	}
	
	term.StopSpinner()
	fmt.Println("📥 Updates available, updating server...")
	term.StartSpinner("Updating code...")
	
	// Update to latest
	resetCmd := exec.Command("git", "reset", "--hard", "origin/main")
	resetCmd.Stdout = nil
	resetCmd.Stderr = nil
	err = resetCmd.Run()
	if err != nil {
		term.StopSpinner()
		term.OutputErrorAndExit("Could not update server code: %v", err)
	}
	
	term.StopSpinner()
	
	// Check if Docker containers are running and restart them
	appDir := filepath.Join(serverDir, "app")
	err = os.Chdir(appDir)
	if err != nil {
		term.OutputErrorAndExit("Could not change to app directory: %v", err)
	}
	
	// Check if containers are running
	psCmd := exec.Command("docker", "compose", "ps", "-q")
	psOut, err := psCmd.Output()
	if err == nil && len(strings.TrimSpace(string(psOut))) > 0 {
		fmt.Println("🐳 Restarting Docker containers...")
		term.StartSpinner("Stopping containers...")
		
		// Stop containers
		downCmd := exec.Command("docker", "compose", "down")
		downCmd.Stdout = nil
		downCmd.Stderr = nil
		downCmd.Run()
		
		term.StopSpinner()
		term.StartSpinner("Rebuilding server...")
		
		// Rebuild
		buildCmd := exec.Command("docker", "compose", "build", "plandex-server")
		buildCmd.Stdout = nil
		buildCmd.Stderr = nil
		err = buildCmd.Run()
		if err != nil {
			term.StopSpinner()
			log.Printf("Warning: Could not rebuild server: %v", err)
		}
		
		term.StopSpinner()
		term.StartSpinner("Starting containers...")
		
		// Start containers
		upCmd := exec.Command("docker", "compose", "up", "-d")
		upCmd.Stdout = nil
		upCmd.Stderr = nil
		err = upCmd.Run()
		if err != nil {
			term.StopSpinner()
			term.OutputErrorAndExit("Could not restart containers: %v", err)
		}
		
		term.StopSpinner()
		fmt.Println("✅ Local server updated and restarted successfully!")
		fmt.Println("   Server is running at: http://localhost:8099")
	} else {
		fmt.Println("✅ Local server code updated successfully!")
		fmt.Printf("   To start the server, run: cd %s && docker compose up -d\n", appDir)
	}
}
