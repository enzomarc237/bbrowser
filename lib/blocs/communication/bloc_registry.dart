import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../base/base_bloc.dart';

/// Registry for managing BLoC instances and their dependencies
/// 
/// This class provides a centralized way to register, retrieve, and manage
/// BLoC instances throughout the application. It helps with dependency
/// injection and prevents circular dependencies.
/// 
/// Example:
/// ```dart
/// // Register BLoCs
/// BlocRegistry.instance.register<TabBloc>(() => TabBloc());
/// BlocRegistry.instance.register<NavigationBloc>(() => NavigationBloc(
///   tabBloc: BlocRegistry.instance.get<TabBloc>(),
/// ));
/// 
/// // Retrieve BLoCs
/// final tabBloc = BlocRegistry.instance.get<TabBloc>();
/// ```
class BlocRegistry {
  static final BlocRegistry _instance = BlocRegistry._internal();
  static BlocRegistry get instance => _instance;

  BlocRegistry._internal();

  final Map<Type, BlocBase> _blocs = {};
  final Map<Type, BlocBase Function()> _factories = {};
  final Map<Type, List<Type>> _dependencies = {};
  final Map<Type, BlocRegistryEntry> _entries = {};

  /// Register a BLoC with a factory function
  /// 
  /// The factory function will be called when the BLoC is first requested.
  void register<T extends BlocBase>(
    T Function() factory, {
    List<Type>? dependencies,
    bool singleton = true,
    String? name,
  }) {
    _factories[T] = factory;
    
    if (dependencies != null) {
      _dependencies[T] = dependencies;
    }

    _entries[T] = BlocRegistryEntry<T>(
      factory: factory,
      dependencies: dependencies ?? [],
      singleton: singleton,
      name: name ?? T.toString(),
    );
  }

  /// Register an existing BLoC instance
  /// 
  /// This is useful for registering pre-created BLoC instances.
  void registerInstance<T extends BlocBase>(T bloc, {String? name}) {
    _blocs[T] = bloc;
    _entries[T] = BlocRegistryEntry<T>(
      factory: () => bloc,
      dependencies: [],
      singleton: true,
      name: name ?? T.toString(),
      isPreCreated: true,
    );
  }

  /// Get a BLoC instance
  /// 
  /// If the BLoC hasn't been created yet, it will be created using
  /// the registered factory function.
  T get<T extends BlocBase>() {
    // Check if instance already exists
    if (_blocs.containsKey(T)) {
      return _blocs[T] as T;
    }

    // Check if factory exists
    if (!_factories.containsKey(T)) {
      throw BlocRegistryException('BLoC of type $T is not registered');
    }

    // Check dependencies
    final dependencies = _dependencies[T];
    if (dependencies != null) {
      for (final dependency in dependencies) {
        if (!_blocs.containsKey(dependency) && !_factories.containsKey(dependency)) {
          throw BlocRegistryException(
            'Dependency $dependency for BLoC $T is not registered'
          );
        }
      }
    }

    // Create instance
    final factory = _factories[T]!;
    final bloc = factory() as T;
    
    // Store instance if singleton
    final entry = _entries[T];
    if (entry?.singleton == true) {
      _blocs[T] = bloc;
    }

    return bloc;
  }

  /// Get a BLoC instance by name
  T getByName<T extends BlocBase>(String name) {
    final entry = _entries.values.firstWhere(
      (entry) => entry.name == name,
      orElse: () => throw BlocRegistryException('BLoC with name "$name" not found'),
    );

    return get<T>();
  }

  /// Check if a BLoC type is registered
  bool isRegistered<T extends BlocBase>() {
    return _factories.containsKey(T) || _blocs.containsKey(T);
  }

  /// Check if a BLoC instance exists
  bool hasInstance<T extends BlocBase>() {
    return _blocs.containsKey(T);
  }

  /// Unregister a BLoC type
  /// 
  /// This will remove the factory and close any existing instance.
  Future<void> unregister<T extends BlocBase>() async {
    // Close existing instance if it exists
    if (_blocs.containsKey(T)) {
      final bloc = _blocs[T]!;
      await bloc.close();
      _blocs.remove(T);
    }

    // Remove factory and dependencies
    _factories.remove(T);
    _dependencies.remove(T);
    _entries.remove(T);
  }

  /// Clear all registered BLoCs
  /// 
  /// This will close all existing instances and clear all registrations.
  Future<void> clear() async {
    // Close all existing instances
    for (final bloc in _blocs.values) {
      await bloc.close();
    }

    // Clear all maps
    _blocs.clear();
    _factories.clear();
    _dependencies.clear();
    _entries.clear();
  }

  /// Get all registered BLoC types
  List<Type> get registeredTypes => _factories.keys.toList();

  /// Get all active BLoC instances
  List<BlocBase> get activeInstances => _blocs.values.toList();

  /// Get dependency graph
  Map<Type, List<Type>> get dependencyGraph => Map.from(_dependencies);

  /// Validate dependency graph for circular dependencies
  /// 
  /// Throws BlocRegistryException if circular dependencies are found.
  void validateDependencies() {
    final visited = <Type>{};
    final recursionStack = <Type>{};

    for (final type in _dependencies.keys) {
      if (!visited.contains(type)) {
        if (_hasCyclicDependency(type, visited, recursionStack)) {
          throw BlocRegistryException(
            'Circular dependency detected involving $type'
          );
        }
      }
    }
  }

  /// Check for cyclic dependencies using DFS
  bool _hasCyclicDependency(
    Type type,
    Set<Type> visited,
    Set<Type> recursionStack,
  ) {
    visited.add(type);
    recursionStack.add(type);

    final dependencies = _dependencies[type] ?? [];
    for (final dependency in dependencies) {
      if (!visited.contains(dependency)) {
        if (_hasCyclicDependency(dependency, visited, recursionStack)) {
          return true;
        }
      } else if (recursionStack.contains(dependency)) {
        return true;
      }
    }

    recursionStack.remove(type);
    return false;
  }

  /// Get debug information about the registry
  Map<String, dynamic> getDebugInfo() {
    return {
      'registeredTypes': registeredTypes.map((type) => type.toString()).toList(),
      'activeInstances': activeInstances.length,
      'totalRegistrations': _factories.length,
      'dependencyGraph': _dependencies.map(
        (type, deps) => MapEntry(
          type.toString(),
          deps.map((dep) => dep.toString()).toList(),
        ),
      ),
      'entries': _entries.map(
        (type, entry) => MapEntry(type.toString(), entry.toMap()),
      ),
    };
  }

  /// Create a dependency-ordered list of BLoC types
  /// 
  /// Returns BLoC types in an order where dependencies come before dependents.
  List<Type> getInitializationOrder() {
    final result = <Type>[];
    final visited = <Type>{};

    void visit(Type type) {
      if (visited.contains(type)) return;
      
      visited.add(type);
      
      // Visit dependencies first
      final dependencies = _dependencies[type] ?? [];
      for (final dependency in dependencies) {
        visit(dependency);
      }
      
      result.add(type);
    }

    // Visit all registered types
    for (final type in _factories.keys) {
      visit(type);
    }

    return result;
  }

  /// Initialize all registered BLoCs in dependency order
  /// 
  /// This is useful for eager initialization of all BLoCs.
  Future<void> initializeAll() async {
    final initOrder = getInitializationOrder();
    
    for (final type in initOrder) {
      if (!_blocs.containsKey(type)) {
        // This will create the instance
        final factory = _factories[type];
        if (factory != null) {
          final bloc = factory();
          _blocs[type] = bloc;
        }
      }
    }
  }
}

/// Registry entry containing metadata about a registered BLoC
class BlocRegistryEntry<T extends BlocBase> {
  const BlocRegistryEntry({
    required this.factory,
    required this.dependencies,
    required this.singleton,
    required this.name,
    this.isPreCreated = false,
  });

  final T Function() factory;
  final List<Type> dependencies;
  final bool singleton;
  final String name;
  final bool isPreCreated;

  Map<String, dynamic> toMap() {
    return {
      'type': T.toString(),
      'name': name,
      'singleton': singleton,
      'isPreCreated': isPreCreated,
      'dependencies': dependencies.map((type) => type.toString()).toList(),
    };
  }
}

/// Exception thrown by BlocRegistry
class BlocRegistryException implements Exception {
  const BlocRegistryException(this.message);

  final String message;

  @override
  String toString() => 'BlocRegistryException: $message';
}

/// Mixin for BLoCs that need access to other BLoCs through the registry
/// 
/// This mixin provides convenient methods for accessing other BLoCs
/// without creating direct dependencies.
mixin BlocRegistryMixin<Event, State> on BlocBase<State> {
  /// Get another BLoC from the registry
  T getBlocFromRegistry<T extends BlocBase>() {
    return BlocRegistry.instance.get<T>();
  }

  /// Check if a BLoC is available in the registry
  bool isBlocAvailable<T extends BlocBase>() {
    return BlocRegistry.instance.isRegistered<T>() &&
           BlocRegistry.instance.hasInstance<T>();
  }

  /// Get a BLoC if it's available, otherwise return null
  T? getBlocIfAvailable<T extends BlocBase>() {
    try {
      return isBlocAvailable<T>() ? getBlocFromRegistry<T>() : null;
    } catch (e) {
      return null;
    }
  }
}

/// Helper class for setting up BLoC dependencies
class BlocDependencyBuilder {
  final Map<Type, BlocBase Function()> _factories = {};
  final Map<Type, List<Type>> _dependencies = {};

  /// Add a BLoC with its dependencies
  BlocDependencyBuilder add<T extends BlocBase>(
    T Function() factory, {
    List<Type>? dependencies,
  }) {
    _factories[T] = factory;
    if (dependencies != null) {
      _dependencies[T] = dependencies;
    }
    return this;
  }

  /// Build and register all BLoCs
  void build() {
    // Validate dependencies first
    final tempRegistry = BlocRegistry();
    tempRegistry._dependencies.addAll(_dependencies);
    tempRegistry.validateDependencies();

    // Register all BLoCs
    for (final entry in _factories.entries) {
      BlocRegistry.instance.register(
        entry.value,
        dependencies: _dependencies[entry.key],
      );
    }
  }
}
