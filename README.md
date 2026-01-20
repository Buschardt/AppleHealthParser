# Apple Health Parser
Parse data from apple health and only include step and heart rate data from the Huawei Health App.

## Dependencies

- install R
- Install packages `install.packages('renv'); renv::restore()`

## How to use

1. Place your files in the Input directory. Each persons data should be within a sub directory:

```
.
├── AppleHealthParser.r
├── Input/
│   ├── User_A/
│   │   └── export.xml
│   ├── User_B/
│   │   └── export.xml
│   └── User_C/
│       └── export.xml
└── Output/            <-- Results will appear here
```

2. Run the AppleHealthParser.r script

3. get the parsed data from the Output directory
