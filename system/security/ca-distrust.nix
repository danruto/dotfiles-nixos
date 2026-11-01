{
  # Distrust until nixpkgs' CA bundle drops them: https://emudhra.we-have-a-problem.com/
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ];
}
