import 'package:go_router/go_router.dart';
import 'package:zelvira/models/checkout_model.dart';
import 'package:zelvira/models/news_model.dart';
import 'package:zelvira/pages/profile/rating_page.dart';
import '../pages/home/main_page.dart';
import '../models/user_model.dart';
import '../pages/home/profile_edit_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/checkout/checkout_page.dart';
import '../pages/order/order_detail_page.dart';
import '../pages/search/search_page.dart';
import '../pages/news/news_detail_page.dart';
import '../pages/address/address_list_page.dart';
import '../pages/address/address_form_page.dart';
import '../pages/home/wishlist_page.dart';
import '../pages/home/trending_page.dart';
import '../pages/home/trending_detail_page.dart';
import '../models/content_section_model.dart';
import '../pages/home/news_page.dart';
import '../pages/home/featured_products_page.dart';
import '../pages/notification/notification_list_page.dart';
import '../pages/cart/cart_page.dart';
import '../pages/auth/whatsapp_login_page.dart';
import '../pages/auth/otp_verification_page.dart';
import '../pages/support/chat_support_page.dart';
import '../pages/onboarding/introduction_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/forgot_password_otp_page.dart';
import '../pages/auth/create_new_password_page.dart';
import '../pages/onboarding/splash_screen.dart';
import '../pages/support/privacy_policy_page.dart';
import '../pages/support/faq_page.dart';
import '../pages/support/help_center_page.dart';
import '../pages/support/about_page.dart';
import '../pages/profile/settings_page.dart';
import '../pages/profile/membership_page.dart';
import '../pages/profile/voucher_list_page.dart';
import '../pages/digital/digital_category_page.dart';
import '../pages/digital/digital_product_list_page.dart';
import '../pages/digital/digital_checkout_page.dart';
import '../pages/home/all_categories_page.dart';
import '../models/digital_product_model.dart';
import '../pages/profile/wallet_page.dart';
import '../pages/profile/points_page.dart';
import '../pages/error/error_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroductionPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),
      GoRoute(path: '/point', builder: (context, state) => const PointsPage()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/forgot-password-otp',
        builder: (context, state) {
          final email = state.extra as String;
          return ForgotPasswordOtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/auth/create-new-password',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return CreateNewPasswordPage(
            email: data?['email'] ?? '',
            code: data?['code'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/auth/whatsapp',
        builder: (context, state) => const WhatsappLoginPage(),
      ),
      GoRoute(path: '/rating', builder: (context, state) => const RatingPage()),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpVerificationPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/home',
        name: '/home',
        builder: (context, state) => const MainPage(),
      ),

      GoRoute(
        path: '/home/:tab',
        name: 'home-tab',
        builder: (context, state) {
          final tab = int.tryParse(state.pathParameters['tab'] ?? '0') ?? 0;

          return MainPage(initialIndex: tab);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final buyNowData = state.extra as Map<String, dynamic>?;
          return CheckoutPage(buyNowData: buyNowData);
        },
      ),
      GoRoute(
        path: '/order-detail',
        builder: (context, state) {
          final orderData = state.extra as OrderResponse;
          return OrderDetailPage(orderData: orderData);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final categoryId = state.extra as int?;
          return SearchPage(selectedCategoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/news-detail',
        builder: (context, state) {
          final newsData = state.extra as NewsModel;
          return NewsDetailPage(news: newsData);
        },
      ),
      GoRoute(
        path: '/address-list',
        builder: (context, state) => const AddressListPage(),
      ),
      GoRoute(
        path: '/address-form',
        builder: (context, state) {
          final addressData = state.extra as Map<String, dynamic>?;
          return AddressFormPage(addressData: addressData);
        },
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistPage(),
      ),
      GoRoute(
        path: '/trending',
        builder: (context, state) => const TrendingPage(),
      ),
      GoRoute(
        path: '/trending-detail',
        builder: (context, state) {
          final item = state.extra as ContentItem;
          return TrendingDetailPage(item: item);
        },
      ),
      GoRoute(
        path: '/news',
        name: 'news',
        builder: (context, state) => const NewsPage(),
      ),
      GoRoute(
        path: '/featured-products',
        builder: (context, state) => const FeaturedProductsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListPage(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(
        path: '/support/chat',
        builder: (context, state) => const ChatSupportPage(),
      ),
      GoRoute(
        path: '/support/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (context, state) => const FAQPage(),
      ),
      GoRoute(
        path: '/support/help',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/support/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return ProfileEditPage(user: user);
        },
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/profile/membership',
        builder: (context, state) => const MembershipPage(),
      ),
      GoRoute(
        path: '/profile/vouchers',
        builder: (context, state) => const VoucherListPage(),
      ),
      GoRoute(
        path: '/digital-category',
        builder: (context, state) => const DigitalCategoryPage(),
      ),
      GoRoute(
        path: '/all-categories',
        builder: (context, state) => const AllCategoriesPage(),
      ),
      GoRoute(
        path: '/digital-products',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'pulsa';
          final title = state.uri.queryParameters['title'];
          final isPostpaidParam = state.uri.queryParameters['isPostpaid'];
          final isPostpaid = isPostpaidParam != null
              ? isPostpaidParam == 'true'
              : null;
          return DigitalProductListPage(
            category: category,
            title: title,
            isPostpaid: isPostpaid,
          );
        },
      ),
      GoRoute(
        path: '/digital-checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final product = extra['product'] as DigitalProduct;
          final customerNo = extra['customerNo'] as String;
          return DigitalCheckoutPage(product: product, customerNo: customerNo);
        },
      ),
      GoRoute(path: '/points', builder: (context, state) => const PointsPage()),
      GoRoute(
        path: '/error',
        builder: (context, state) {
          final errorMessage =
              state.extra as String? ?? 'An unexpected error occurred.';
          return ErrorPage(errorMessage: errorMessage);
        },
      ),
    ],
  );
}
