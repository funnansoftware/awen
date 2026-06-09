module;

#include <any>
#include <functional>
#include <string>
#include <string_view>
#include <typeinfo>

export module lua.property;

export namespace lua
{
    class Property
    {
    public:
        explicit Property(std::string_view name) : name_{name}
        {
        }

        virtual ~Property() = default;

        Property(const Property&) = delete;
        auto operator=(const Property&) -> Property& = delete;
        Property(Property&&) noexcept = delete;
        auto operator=(Property&&) noexcept -> Property& = delete;

        [[nodiscard]] auto getName() const noexcept -> std::string_view
        {
            return name_;
        }

        template <typename T>
        [[nodiscard]] auto is() const -> bool
        {
            return typeInfo() == typeid(T);
        }

        [[nodiscard]] virtual auto typeInfo() const -> const std::type_info& = 0;

        virtual auto setValueAsString(const std::string& value) -> void = 0;
        virtual auto setValue(const std::any& value) -> void = 0;

    private:
        std::string name_;
    };

    template <typename T>
    class TemplatedProperty : public Property
    {
    public:
        using Getter = std::function<T()>;
        using Setter = std::function<void(const T&)>;

        TemplatedProperty(std::string_view name, Getter getter, Setter setter)
            : Property{name}, getter_{std::move(getter)}, setter_{std::move(setter)}
        {
        }

        auto get() const -> T
        {
            return getter_();
        }

        auto set(const T& value) -> void
        {
            setter_(value);
        }

        [[nodiscard]] auto typeInfo() const -> const std::type_info& override
        {
            return typeid(T);
        }

        auto setValueAsString([[maybe_unused]] const std::string& value) -> void override
        {
            // Implement conversion from string to T and call set()
            // This is a placeholder implementation and should be expanded to handle different types
            // if constexpr (std::is_same_v<T, float>)
            // {
            //     try
            //     {
            //         float floatValue = std::stof(value);
            //         set(floatValue);
            //     }
            //     catch (const std::invalid_argument&)
            //     {
            //         // Handle conversion error
            //     }
            // }
            // else if constexpr (std::is_same_v<T, int>)
            // {
            //     try
            //     {
            //         int intValue = std::stoi(value);
            //         set(intValue);
            //     }
            //     catch (const std::invalid_argument&)
            //     {
            //         // Handle conversion error
            //     }
            // }
            // Add more type conversions as needed
        }

        auto setValue([[maybe_unused]] const std::any& value) -> void override
        {
            // if (value.type() == typeid(T))
            // {
            //     set(std::any_cast<T>(value));
            // }
            // else
            // {
            //     // Handle error: value is not of the expected type
            // }
        }

    private:
        Getter getter_;
        Setter setter_;
    };
}