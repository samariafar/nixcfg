{ config, pkgs, ... }:

{
  editorconfig = {
    enable = true;
    settings = {
      # Note: `root = true` is added automatically by home-manager.
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        indent_size = 4;
        indent_style = "space";
        insert_final_newline = true;
        trim_trailing_whitespace = true;
      };
      "{Dockerfile,Makefile,*.go,*.sh}" = {
        indent_style = "tab";
      };
      "*.{css,js,json,jsx,nix,scss,tf,tfvars,toml,ts,tsx,yaml,yml}" = {
        indent_size = 2;
      };
      "*.{bat,cmd,ps1,reg,wxi,wxl,wxs}" = {
        end_of_line = "crlf";
      };
      "*.md" = {
        trim_trailing_whitespace = false;
      };
    };
  };
}
