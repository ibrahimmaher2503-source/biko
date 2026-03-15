/// Data class representing a single onboarding slide
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.highlightWord,
    required this.description,
    required this.illustration,
    required this.index,
  });

  final String title;
  final String highlightWord;
  final String description;
  final String illustration;
  final int index;

  /// Customer app onboarding slides
  static final customerSlides = [
    const OnboardingSlide(
      title: 'onboarding.customer.slide1.title',
      highlightWord: 'onboarding.customer.slide1.highlight',
      description: 'onboarding.customer.slide1.desc',
      illustration: 'assets/images/onboarding/customer_speed.png',
      index: 0,
    ),
    const OnboardingSlide(
      title: 'onboarding.customer.slide2.title',
      highlightWord: 'onboarding.customer.slide2.highlight',
      description: 'onboarding.customer.slide2.desc',
      illustration: 'assets/images/onboarding/customer_bidding.png',
      index: 1,
    ),
    const OnboardingSlide(
      title: 'onboarding.customer.slide3.title',
      highlightWord: 'onboarding.customer.slide3.highlight',
      description: 'onboarding.customer.slide3.desc',
      illustration: 'assets/images/onboarding/customer_delivery.png',
      index: 2,
    ),
  ];

  /// Driver app onboarding slides
  static final driverSlides = [
    const OnboardingSlide(
      title: 'onboarding.driver.slide1.title',
      highlightWord: 'onboarding.driver.slide1.highlight',
      description: 'onboarding.driver.slide1.desc',
      illustration: 'assets/images/onboarding/driver_freedom.png',
      index: 0,
    ),
    const OnboardingSlide(
      title: 'onboarding.driver.slide2.title',
      highlightWord: 'onboarding.driver.slide2.highlight',
      description: 'onboarding.driver.slide2.desc',
      illustration: 'assets/images/onboarding/driver_trust.png',
      index: 1,
    ),
    const OnboardingSlide(
      title: 'onboarding.driver.slide3.title',
      highlightWord: 'onboarding.driver.slide3.highlight',
      description: 'onboarding.driver.slide3.desc',
      illustration: 'assets/images/onboarding/driver_earnings.png',
      index: 2,
    ),
  ];
}
