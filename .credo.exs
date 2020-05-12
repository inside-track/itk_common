%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      checks: [
        {Credo.Check.Readability.ModuleNames, false},
        {Credo.Check.Refactor.LongQuoteBlocks, max_line_count: 1000, ignore_comments: true},
        {Credo.Check.Readability.MaxLineLength, max_length: 120},
        {Credo.Check.Design.AliasUsage, excluded_namespaces: ~w[ AMQP Mix ]}
      ]
    }
  ]
}
