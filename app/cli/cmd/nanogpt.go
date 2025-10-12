package cmd

import (
	"fmt"
	"plandex-cli/lib"
	"plandex-cli/term"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var nanoGPTCmd = &cobra.Command{
	Use:     "nanogpt",
	Aliases: []string{"nano"},
	Short:   "Check NanoGPT subscription status",
	Run:     nanoGPTStatus,
}

var connectNanoGPTCmd = &cobra.Command{
	Use:   "connect-nanogpt",
	Short: "Enable NanoGPT subscription mode",
	Run:   connectNanoGPT,
}

var disconnectNanoGPTCmd = &cobra.Command{
	Use:   "disconnect-nanogpt",
	Short: "Disable NanoGPT subscription mode (use balance instead)",
	Run:   disconnectNanoGPT,
}

func init() {
	RootCmd.AddCommand(nanoGPTCmd)
	RootCmd.AddCommand(connectNanoGPTCmd)
	RootCmd.AddCommand(disconnectNanoGPTCmd)
}

func nanoGPTStatus(cmd *cobra.Command, args []string) {
	term.StartSpinner("")
	orgUserConfig := lib.MustGetOrgUserConfig()
	term.StopSpinner()

	fmt.Println()
	fmt.Println("🔧 " + color.New(color.FgHiCyan, color.Bold).Sprint("NanoGPT Configuration"))
	fmt.Println()

	if orgUserConfig.UseNanoGPTSubscription {
		fmt.Println("✅ " + color.New(color.FgHiGreen, color.Bold).Sprint("Subscription mode enabled"))
		fmt.Println("   NanoGPT models will use your subscription allowance")
		fmt.Println()
		term.PrintCmds("", "disconnect-nanogpt")
	} else {
		fmt.Println("💰 " + color.New(color.FgHiYellow, color.Bold).Sprint("Balance mode enabled"))
		fmt.Println("   NanoGPT models will use your prepaid balance/credits")
		fmt.Println()
		term.PrintCmds("", "connect-nanogpt")
	}
	fmt.Println()
}

func connectNanoGPT(cmd *cobra.Command, args []string) {
	term.StartSpinner("")
	orgUserConfig := lib.MustGetOrgUserConfig()
	
	if orgUserConfig.UseNanoGPTSubscription {
		term.StopSpinner()
		fmt.Println("✅ NanoGPT subscription mode is already enabled")
		return
	}

	orgUserConfig.UseNanoGPTSubscription = true
	lib.MustUpdateOrgUserConfig(*orgUserConfig)
	term.StopSpinner()

	fmt.Println()
	fmt.Println("✅ " + color.New(color.FgHiGreen, color.Bold).Sprint("NanoGPT subscription mode enabled"))
	fmt.Println()
	fmt.Println("NanoGPT models will now use your subscription allowance instead of balance.")
	fmt.Println()
	fmt.Println("To switch back to balance mode, run:")
	fmt.Println(term.ShowCmd("disconnect-nanogpt"))
	fmt.Println()
}

func disconnectNanoGPT(cmd *cobra.Command, args []string) {
	term.StartSpinner("")
	orgUserConfig := lib.MustGetOrgUserConfig()
	
	if !orgUserConfig.UseNanoGPTSubscription {
		term.StopSpinner()
		fmt.Println("💰 NanoGPT balance mode is already enabled")
		return
	}

	orgUserConfig.UseNanoGPTSubscription = false
	lib.MustUpdateOrgUserConfig(*orgUserConfig)
	term.StopSpinner()

	fmt.Println()
	fmt.Println("💰 " + color.New(color.FgHiYellow, color.Bold).Sprint("NanoGPT balance mode enabled"))
	fmt.Println()
	fmt.Println("NanoGPT models will now use your prepaid balance/credits instead of subscription.")
	fmt.Println()
	fmt.Println("To switch back to subscription mode, run:")
	fmt.Println(term.ShowCmd("connect-nanogpt"))
	fmt.Println()
}
