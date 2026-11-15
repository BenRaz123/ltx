{
  description = "Latex Flakes";
  outputs = _: {
    templates = {
      beamer = ./beamer;
    };
  };
}
