package system

import (
	"os"
	"os/exec"
)

func Run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func Output(name string, args ...string) ([]byte, error) {
	return exec.Command(name, args...).CombinedOutput()
}
