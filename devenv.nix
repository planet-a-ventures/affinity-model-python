{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.bash
    pkgs.python312Packages.openapi-spec-validator
  ];

  # https://devenv.sh/languages/
  languages.python.enable = true;
  languages.python.uv.enable = true;
  languages.python.uv.package = pkgs.uv;
  languages.python.uv.sync.enable = true;
  languages.python.uv.sync.allExtras = true;
  languages.python.venv.enable = true;
  languages.python.version = "3.12";

  git-hooks.hooks = {
    shellcheck.enable = true;
    black.enable = true;
    typos.enable = true;
    yamllint.enable = true;
    yamlfmt.enable = true;
    commitizen.enable = true;
    nixfmt-rfc-style.enable = true;
    markdownlint.enable = true;
  };

  # TODO: Replace with https://github.com/cachix/git-hooks.nix/pull/557 when merged
  git-hooks.hooks.validate-spec = {
    enable = true;

    # The name of the hook (appears on the report table):
    name = "Validate OpenAPI spec";

    # The command to execute (mandatory):
    entry = "openapi-spec-validator";

    # The pattern of files to run on (default: "" (all))
    # see also https://pre-commit.com/#hooks-files
    files = "^spec/.*\\.(yaml|yml|json)$";

    # The language of the hook - tells pre-commit
    # how to install the hook (default: "system")
    # see also https://pre-commit.com/#supported-languages
    language = "system";

    # Set this to false to not pass the changed files
    # to the command (default: true):
    pass_filenames = true;
  };

  scripts.lint-spec.exec = ''
    openapi-spec-validator $DEVENV_ROOT/spec/*.json
  '';

  scripts.create-model-patch.exec = ''
    cd $DEVENV_ROOT/spec
    git diff v2_spec.json > v2_spec.patch
  '';

  scripts.generate-model.exec = ''
    $DEVENV_ROOT/bin/generate_model.sh
  '';

  scripts.format.exec = ''
    yamlfmt .
    markdownlint --fix .
    pre-commit run --all-files
  '';

  scripts.test-all.exec = ''
    pytest -s -vv "$@"
  '';

  enterTest = ''
    test-all
  '';

  scripts.test-watch.exec = ''
    ptw .
  '';

  scripts.test-update-snapshots.exec = ''
    pytest --snapshot-update
  '';

  scripts.build.exec = ''
    uv build
  '';

}
