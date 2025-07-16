{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{

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
    shellcheck.excludes = [
      ".envrc"
    ];
    black.enable = true;
    typos.enable = true;
    typos.excludes = [
      "spec/v2_spec.json"
    ];
    yamllint.enable = true;
    yamlfmt.enable = true;
    commitizen.enable = true;
    nixfmt-rfc-style.enable = true;
    markdownlint.enable = true;
    openapi-spec-validator.enable = true;
    openapi-spec-validator.files = "^spec/.*\\.(yaml|yml|json)$";
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
