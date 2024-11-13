{
  description = "Ready-made templates for easily creating development environments";

  outputs =
    { self }:
    {
      templates = {
        react-native = {
          path = ./react-native;
          description = "React Native development environment";
        };

        default = self.templates.react-native;
      };
    };
}
