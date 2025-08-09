
# 1. Build the publisher:
dotnet new console -n PublisherApp -o PublisherApp
dotnet add reference C:\cpp-prj\DDSexampel\swig\ICDWrapperCsharp\ICDWrapperSharp.csproj
dotnet build -c Release
cd ..


# 3. Build the subscriber:
dotnet new console -n SubscriberApp -o SubscriberApp
dotnet add reference C:\cpp-prj\DDSexampel\swig\ICDWrapperCsharp\ICDWrapperSharp.csproj
dotnet build -c Release
cd ..


# 4. Run the subscriber:
cd SubscriberApp
dotnet run

# 5. Run the publisher:
cd PublisherApp
dotnet run
cd ..