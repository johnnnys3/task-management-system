import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/constants/app_constants.dart';
import 'package:task_management/core/constants/app_strings.dart';
import 'package:task_management/presentation/widgets/optimized_summary_card.dart';

void main() {
  group('OptimizedSummaryCard Widget Tests', () {
    testWidgets('should display card with correct data', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 5,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('5'), findsOneWidget);
      expect(find.text(AppStrings.completed), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should have correct colors and styling', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 10,
        label: AppStrings.inProgress,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.primaryBlue));
      
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final countText = textWidgets.firstWhere((text) => text.data == '10');
      expect(countText.style?.color, equals(Colors.white));
    });

    testWidgets('should handle different icon types', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.surfaceLight,
        icon: Icons.pending_outlined,
        count: 3,
        label: AppStrings.pending,
        textColor: AppColors.primaryPurple,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.pending_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(AppStrings.pending), findsOneWidget);
    });

    testWidgets('should layout components correctly', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.access_time,
        count: 7,
        label: AppStrings.inProgress,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      // Check that icon container exists
      expect(find.byType(Container), findsWidgets);
      
      // Check that text elements exist
      expect(find.byType(Text), findsWidgets);
      
      // Check that icon exists
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('should be const constructible', (WidgetTester tester) async {
      // Arrange & Act
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 1,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert - If this compiles and runs without error, the const constructor works
      expect(find.byType(OptimizedSummaryCard), findsOneWidget);
    });

    testWidgets('should handle zero count', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.surfaceLight,
        icon: Icons.check_circle_outline,
        count: 0,
        label: AppStrings.completed,
        textColor: AppColors.primaryBlue,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsOneWidget);
      expect(find.text(AppStrings.completed), findsOneWidget);
    });

    testWidgets('should handle large count values', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 999999,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('999999'), findsOneWidget);
    });

    testWidgets('should have correct padding and spacing', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 5,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, equals(const EdgeInsets.all(AppSpacing.cardPadding)));
    });

    testWidgets('should have correct border radius', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 5,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(AppRadius.lg)));
    });

    testWidgets('should have box shadow', (WidgetTester tester) async {
      // Arrange
      const card = OptimizedSummaryCard(
        backgroundColor: AppColors.primaryBlue,
        icon: Icons.check_circle_outline,
        count: 5,
        label: AppStrings.completed,
        textColor: Colors.white,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, equals(AppElevation.md));
    });
  });

  group('SummaryCardFactory Tests', () {
    testWidgets('should create completed card', (WidgetTester tester) async {
      // Arrange & Act
      final card = SummaryCardFactory.completed(10);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('10'), findsOneWidget);
      expect(find.text(AppStrings.completed), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should create in progress card', (WidgetTester tester) async {
      // Arrange & Act
      final card = SummaryCardFactory.inProgress(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('5'), findsOneWidget);
      expect(find.text(AppStrings.inProgress), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('should create pending card', (WidgetTester tester) async {
      // Arrange & Act
      final card = SummaryCardFactory.pending(3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      // Assert
      expect(find.text('3'), findsOneWidget);
      expect(find.text(AppStrings.pending), findsOneWidget);
      expect(find.byIcon(Icons.pending_outlined), findsOneWidget);
    });

    testWidgets('should have correct colors for different card types', (WidgetTester tester) async {
      // Test completed card (blue background, white text)
      final completedCard = SummaryCardFactory.completed(5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: completedCard,
          ),
        ),
      );
      
      final completedContainer = tester.widget<Container>(find.byType(Container).first);
      final completedDecoration = completedContainer.decoration as BoxDecoration;
      expect(completedDecoration.color, equals(AppColors.primaryBlue));
      
      // Clean up
      await tester.pumpWidget(Container());

      // Test in progress card (light background, blue text)
      final inProgressCard = SummaryCardFactory.inProgress(5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: inProgressCard,
          ),
        ),
      );
      
      final inProgressContainer = tester.widget<Container>(find.byType(Container).first);
      final inProgressDecoration = inProgressContainer.decoration as BoxDecoration;
      expect(inProgressDecoration.color, equals(AppColors.surfaceLight));
    });
  });
}
