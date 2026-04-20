.PHONY: nomad-up nomad-down nomad-restart nomad-status

nomad-up:
	@./scripts/nomad-up.sh

nomad-down:
	@./scripts/nomad-down.sh

nomad-restart: nomad-down nomad-up

nomad-status:
	@nomad job status
