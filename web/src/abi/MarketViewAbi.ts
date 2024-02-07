export const MarketViewAbi = [
  {
    inputs: [
      {
        internalType: "contract IConditionalTokens",
        name: "conditionalTokens",
        type: "address",
      },
      {
        internalType: "contract IRealityETH_v3_0",
        name: "realitio",
        type: "address",
      },
      {
        internalType: "address",
        name: "marketId",
        type: "address",
      },
    ],
    name: "getMarket",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "id",
            type: "address",
          },
          {
            internalType: "string",
            name: "marketName",
            type: "string",
          },
          {
            internalType: "string[]",
            name: "outcomes",
            type: "string[]",
          },
          {
            internalType: "bytes32",
            name: "conditionId",
            type: "bytes32",
          },
          {
            internalType: "bytes32",
            name: "questionId",
            type: "bytes32",
          },
          {
            internalType: "uint256",
            name: "templateId",
            type: "uint256",
          },
          {
            internalType: "string",
            name: "encodedQuestion",
            type: "string",
          },
          {
            internalType: "address",
            name: "oracle",
            type: "address",
          },
          {
            internalType: "address[]",
            name: "pools",
            type: "address[]",
          },
          {
            components: [
              {
                internalType: "bytes32",
                name: "content_hash",
                type: "bytes32",
              },
              {
                internalType: "address",
                name: "arbitrator",
                type: "address",
              },
              {
                internalType: "uint32",
                name: "opening_ts",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "timeout",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "finalize_ts",
                type: "uint32",
              },
              {
                internalType: "bool",
                name: "is_pending_arbitration",
                type: "bool",
              },
              {
                internalType: "uint256",
                name: "bounty",
                type: "uint256",
              },
              {
                internalType: "bytes32",
                name: "best_answer",
                type: "bytes32",
              },
              {
                internalType: "bytes32",
                name: "history_hash",
                type: "bytes32",
              },
              {
                internalType: "uint256",
                name: "bond",
                type: "uint256",
              },
              {
                internalType: "uint256",
                name: "min_bond",
                type: "uint256",
              },
            ],
            internalType: "struct IRealityETH_v3_0.Question",
            name: "question",
            type: "tuple",
          },
        ],
        internalType: "struct MarketView.MarketInfo",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "count",
        type: "uint256",
      },
      {
        internalType: "contract IMarketFactory",
        name: "marketFactory",
        type: "address",
      },
    ],
    name: "getMarkets",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "id",
            type: "address",
          },
          {
            internalType: "string",
            name: "marketName",
            type: "string",
          },
          {
            internalType: "string[]",
            name: "outcomes",
            type: "string[]",
          },
          {
            internalType: "bytes32",
            name: "conditionId",
            type: "bytes32",
          },
          {
            internalType: "bytes32",
            name: "questionId",
            type: "bytes32",
          },
          {
            internalType: "uint256",
            name: "templateId",
            type: "uint256",
          },
          {
            internalType: "string",
            name: "encodedQuestion",
            type: "string",
          },
          {
            internalType: "address",
            name: "oracle",
            type: "address",
          },
          {
            internalType: "address[]",
            name: "pools",
            type: "address[]",
          },
          {
            components: [
              {
                internalType: "bytes32",
                name: "content_hash",
                type: "bytes32",
              },
              {
                internalType: "address",
                name: "arbitrator",
                type: "address",
              },
              {
                internalType: "uint32",
                name: "opening_ts",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "timeout",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "finalize_ts",
                type: "uint32",
              },
              {
                internalType: "bool",
                name: "is_pending_arbitration",
                type: "bool",
              },
              {
                internalType: "uint256",
                name: "bounty",
                type: "uint256",
              },
              {
                internalType: "bytes32",
                name: "best_answer",
                type: "bytes32",
              },
              {
                internalType: "bytes32",
                name: "history_hash",
                type: "bytes32",
              },
              {
                internalType: "uint256",
                name: "bond",
                type: "uint256",
              },
              {
                internalType: "uint256",
                name: "min_bond",
                type: "uint256",
              },
            ],
            internalType: "struct IRealityETH_v3_0.Question",
            name: "question",
            type: "tuple",
          },
        ],
        internalType: "struct MarketView.MarketInfo[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;