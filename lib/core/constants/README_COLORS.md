# App Color Scheme

This document describes the new color scheme for the TradeSuper app.

## Main Theme Colors

### 1. Primary Background Color

- **Hex**: `#FFFFFF`
- **Usage**: Main background color for screens, containers, and large surfaces
- **Access**: `AppColors.primaryBackground`

### 2. Secondary Background Color

- **Hex**: `#FFBD4D`
- **Usage**: Creative design elements above white background (headers, decorative shapes, accent sections)
- **Access**: `AppColors.secondaryBackground`

### 3. Primary Text Color

- **Hex**: `#FF5C01`
- **Usage**: Primary text color, buttons, accents, and interactive elements
- **Access**: `AppColors.primaryText`

### 3. White

- **Hex**: `#FFFFFF`
- **Usage**: Card backgrounds, input fields, and contrast surfaces
- **Access**: `AppColors.white`

## Additional Colors

### Light Background

- **Hex**: `#FFD280`
- **Usage**: Lighter version of primary background for subtle variations
- **Access**: `AppColors.lightBackground`

### Dark Text

- **Hex**: `#E64A00`
- **Usage**: Darker version of primary text for emphasis
- **Access**: `AppColors.darkText`

### Utility Colors

- **Error**: `#D32F2F` - For error messages and validation
- **Success**: `#388E3C` - For success messages and confirmations
- **Warning**: `#FFA000` - For warning messages
- **Secondary Text**: `#757575` - For less important text

## Usage Examples

### Basic Container

```dart
Container(
  color: AppColors.primaryBackground,
  child: Text(
    'Content',
    style: TextStyle(color: AppColors.primaryText),
  ),
)
```

### Card with White Background

```dart
Card(
  color: AppColors.white,
  child: Text(
    'Card Content',
    style: TextStyle(color: AppColors.primaryText),
  ),
)
```

### Button

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryText,
    foregroundColor: AppColors.white,
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

### Text Styling

```dart
Text(
  'Heading',
  style: TextStyle(
    color: AppColors.primaryText,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

## Color Combinations

### Creative Design Elements

- Background: `AppColors.secondaryBackground`
- Text: `AppColors.white`
- Use for headers, decorative shapes, and accent sections

### Clean Surface

- Background: `AppColors.white`
- Text: `AppColors.primaryText`
- Use for cards, input fields, and content containers

### Subtle Variation

- Background: `AppColors.lightBackground`
- Text: `AppColors.primaryText`
- Use for secondary containers and subtle backgrounds

## Migration Notes

The old color constants have been preserved for backward compatibility:

- `AppTheme.primaryColor` now maps to `AppColors.primaryText`
- `AppTheme.backgroundColor` now maps to `AppColors.primaryBackground`
- `AppTheme.surfaceColor` now maps to `AppColors.white`

## Best Practices

1. **Use primaryBackground (white) for main screen backgrounds**
2. **Use secondaryBackground for creative design elements (headers, decorative shapes)**
3. **Use white for cards and input fields**
4. **Use primaryText for headings and important text**
5. **Maintain good contrast ratios for accessibility**
6. **Use utility colors sparingly and consistently**

## Accessibility

- The color combinations have been tested for sufficient contrast
- Primary text on primary background provides good readability
- White surfaces with primary text ensure maximum contrast
- Consider using opacity variations for subtle effects
