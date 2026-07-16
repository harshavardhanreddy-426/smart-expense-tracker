# Software Architecture Document (SAD)
## Smart Expense Tracker Web Application

**Document Version:** 1.0  
**Last Updated:** July 2026  
**Status:** Final  
**Architecture Lead:** [Your Name]  
**Technology Stack:** React 18+, Spring Boot 3.0+, Spring Security, JWT, JPA/Hibernate, MySQL 8.0+

---

## Table of Contents

1. [Introduction](#introduction)
2. [High-Level Architecture](#high-level-architecture)
3. [System Architecture Diagram](#system-architecture-diagram)
4. [Technology Stack](#technology-stack)
5. [Layered Backend Architecture](#layered-backend-architecture)
6. [Frontend Architecture](#frontend-architecture)
7. [Module Breakdown](#module-breakdown)
8. [Request Flow](#request-flow)
9. [Authentication Flow (JWT)](#authentication-flow-jwt)
10. [Database Interaction Flow](#database-interaction-flow)
11. [Folder Structure](#folder-structure)
12. [Design Patterns](#design-patterns)
13. [Security Architecture](#security-architecture)
14. [Deployment Architecture](#deployment-architecture)
15. [Sequence Diagrams](#sequence-diagrams)
16. [Future Scalability Considerations](#future-scalability-considerations)
17. [References](#references)

---

## Introduction

### 1.1 Purpose

This Software Architecture Document (SAD) defines the architectural design of the Smart Expense Tracker application, providing a comprehensive blueprint for development, deployment, and maintenance. It serves as a reference for developers, architects, and stakeholders to understand the system's structure, behavior, and interactions.

### 1.2 Scope

This document covers:
- System architecture and component design
- Technology stack and tool selection rationale
- Data flow and interaction patterns
- Security mechanisms and implementation
- Deployment and scaling strategies
- Design patterns and best practices

### 1.3 Stakeholders

- Development Team (Backend & Frontend)
- DevOps/Infrastructure Team
- QA/Testing Team
- System Architects
- Security Team
- Project Managers

---

## High-Level Architecture

### 2.1 Architecture Overview

The Smart Expense Tracker follows a **three-tier client-server architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│              (React SPA - Web Browser, Mobile)                   │
└─────────────────────────────────────────────────────────────────┘
                              ↕
                        (HTTP/REST)
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                           │
│        (Spring Boot - REST API, Business Logic, JWT Auth)       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │          Spring Security + JWT Authentication            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Controllers → Services → Repositories → ORM (JPA/HIB)   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↕
                        (JDBC/SQL)
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│                 (MySQL Database & Cache)                         │
│                                                                   │
│  ┌──────────────────────┐        ┌──────────────────────┐       │
│  │   MySQL Database     │        │  Redis Cache         │       │
│  │  (Primary Storage)   │        │  (Optional)          │       │
│  └──────────────────────┘        └──────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Core Principles

- **Separation of Concerns:** Each layer has distinct responsibilities
- **Stateless Backend:** Enables horizontal scaling and load balancing
- **JWT-Based Authentication:** Stateless token-based security
- **RESTful API Design:** Standard HTTP methods and status codes
- **Loose Coupling:** Services communicate through well-defined interfaces
- **High Cohesion:** Related functionality grouped together
- **Security by Design:** Encryption, validation, and access control at all layers

---

## System Architecture Diagram

### 3.1 Complete System Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                             END USER TIER                                  │
│  ┌──────────────────────────┐         ┌──────────────────────────┐         │
│  │   Web Browser (React)    │         │  Mobile Browser (React)  │         │
│  │  - Dashboard            │         │  - Dashboard             │         │
│  │  - Expense Management   │         │  - Expense Management    │         │
│  │  - Reports              │         │  - Reports               │         │
│  └──────────────────────────┘         └──────────────────────────┘         │
└────────────────────────────────────────────────────────────────────────────┘
                                    ↕
                            (HTTPS/REST API)
                                    ↕
┌────────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY / LOAD BALANCER                          │
│                    (Nginx, AWS ELB, or similar)                            │
│                    - Request routing                                        │
│                    - Rate limiting                                          │
│                    - HTTPS termination                                      │
└────────────────────────────────────────────────────────────────────────────┘
                                    ↕
            ┌───────────────────────┼───────────────────────┐
            ↓                       ↓                       ↓
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│  Spring Boot App     │ │  Spring Boot App     │ │  Spring Boot App     │
│  Instance 1          │ │  Instance 2          │ │  Instance N          │
│                      │ │                      │ │                      │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │  Controllers   │  │ │  │  Controllers   │  │ │  │  Controllers   │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│         ↓            │ │         ↓            │ │         ↓            │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │ Authentication │  │ │  │ Authentication │  │ │  │ Authentication │  │
│  │  & Security    │  │ │  │  & Security    │  │ │  │  & Security    │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│         ↓            │ │         ↓            │ │         ↓            │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │   Services     │  │ │  │   Services     │  │ │  │   Services     │  │
│  │  Layer         │  │ │  │  Layer         │  │ │  │  Layer         │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│         ↓            │ │         ↓            │ │         ↓            │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │  Repositories  │  │ │  │  Repositories  │  │ │  │  Repositories  │  │
│  │  (JPA)         │  │ │  │  (JPA)         │  │ │  │  (JPA)         │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│         ↓            │ │         ↓            │ │         ↓            │
│         └──────┬─────┘ │         └──────┬─────┘ │         └──────┬─────┘
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘
                               ↓
                    ┌──────────────────────────┐
                    │   Shared Cache Layer     │
                    │   (Redis - Optional)     │
                    │   - Session cache        │
                    │   - Query results        │
                    │   - Category cache       │
                    └──────────────────────────┘
                               ↓
        ┌──────────────────────┴──────────────────────┐
        ↓                                             ↓
┌──────────────────────────┐            ┌──────────────────────────┐
│   Primary Database       │            │  Database Replica        │
│   (MySQL Master)         │            │  (MySQL Slave/Read)      │
│                          │            │                          │
│  ┌────────────────────┐  │            │  ┌────────────────────┐  │
│  │  Users             │  │            │  │  Users             │  │
│  │  Expenses          │  │            │  │  Expenses          │  │
│  │  Categories        │  │            │  │  Categories        │  │
│  │  Budgets           │  │            │  │  Budgets           │  │
│  │  AuditLogs         │  │            │  │  AuditLogs         │  │
│  └────────────────────┘  │            │  └────────────────────┘  │
└──────────────────────────┘            └──────────────────────────┘
        ↑                                        ↑
        └────────────────┬─────────────────────┘
                         │
                    (Replication)
```

### 3.2 Service Communication

```
┌─────────────────────┐
│   React Frontend    │
│                     │
│  Components         │
│    ↓               │
│  Redux Store      │  (State Management)
│    ↓               │
│  HTTP Client       │  (Axios)
│                     │
└──────────┬──────────┘
           │
      HTTPS/REST
           │
┌──────────↓──────────┐
│  Spring Boot API    │
│                     │
│  Controllers        │  (Route & Validate)
│    ↓               │
│  Services          │  (Business Logic)
│    ↓               │
│  Repositories      │  (Data Access)
│    ↓               │
│  JPA/Hibernate    │  (ORM)
│                     │
└──────────┬──────────┘
           │
        JDBC
           │
┌──────────↓──────────┐
│  MySQL Database     │
│                     │
│  Tables             │
│  Indexes            │
│  Stored Procedures  │
│                     │
└─────────────────────┘
```

---

## Technology Stack

### 4.1 Frontend Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | React | 18+ | UI components and rendering |
| **State Management** | Redux or Context API | 4.2+ / Built-in | Global state management |
| **HTTP Client** | Axios | 1.4+ | REST API calls |
| **Routing** | React Router | 6+ | Client-side routing |
| **UI Components** | Material-UI or Tailwind CSS | Latest | Pre-built styled components |
| **Charts** | Chart.js / Recharts | Latest | Data visualization |
| **Form Handling** | Formik / React Hook Form | Latest | Form validation and management |
| **Testing** | Jest + React Testing Library | Latest | Unit and component tests |
| **Build Tool** | Vite / Webpack | Latest | Module bundling |
| **Linting** | ESLint | Latest | Code quality |
| **Formatting** | Prettier | Latest | Code formatting |
| **Date Handling** | Day.js | 1.11+ | Date manipulation |
| **HTTP Interceptors** | Axios Interceptors | Built-in | Auth token injection |

### 4.2 Backend Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | Spring Boot | 3.0+ | Application framework |
| **Security** | Spring Security | 6.0+ | Authentication & Authorization |
| **Data Access** | Spring Data JPA | Latest | ORM integration |
| **ORM** | Hibernate | 6.0+ | Object-relational mapping |
| **API Documentation** | Springdoc OpenAPI | 1.7+ | API documentation (Swagger) |
| **Validation** | Jakarta Bean Validation | Latest | Input validation |
| **Logging** | SLF4J + Logback | Latest | Logging framework |
| **JSON Processing** | Jackson | 2.14+ | JSON serialization |
| **Testing** | JUnit 5 + Mockito | Latest | Unit and integration tests |
| **Build Tool** | Maven | 3.8+ | Build automation |
| **Database Driver** | MySQL JDBC | 8.0+ | Database connectivity |
| **Caching** | Spring Cache Abstraction | Built-in | Caching layer (Redis optional) |
| **Task Scheduling** | Spring Scheduler | Built-in | Async tasks & notifications |
| **Email** | Spring Mail | Built-in | Email notifications |

### 4.3 Database Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Primary DB** | MySQL | 8.0+ | Main relational database |
| **Cache (Optional)** | Redis | 6.0+ | Session & query caching |
| **Connection Pool** | HikariCP | Latest | Connection pooling |
| **Migration Tool** | Flyway | Latest | Database schema versioning |

### 4.4 DevOps & Infrastructure

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Containerization** | Docker | Latest | Container management |
| **Orchestration** | Docker Compose / K8s | Latest | Multi-container orchestration |
| **CI/CD** | GitHub Actions / Jenkins | Latest | Automated testing & deployment |
| **Version Control** | Git | Latest | Source code management |
| **Monitoring** | Prometheus + Grafana | Latest | Performance monitoring |
| **Log Aggregation** | ELK Stack / Cloud Logging | Latest | Centralized logging |
| **Load Balancer** | Nginx / AWS ELB | Latest | Traffic distribution |
| **Hosting** | AWS / GCP / Azure | Latest | Cloud infrastructure |

### 4.5 Rationale for Technology Choices

**Frontend - React:**
- Large ecosystem and community support
- Component-based architecture aligns with modular design
- Excellent tooling and development experience
- Strong performance with virtual DOM
- Good for mobile-responsive design

**Backend - Spring Boot:**
- Industry-standard Java framework
- Extensive security features via Spring Security
- Rich ecosystem (Spring Data, Spring Cloud)
- Excellent documentation and community
- Strong support for enterprise patterns

**Database - MySQL:**
- Reliable and proven RDBMS
- Good for relational financial data
- Excellent scaling options (replication, sharding)
- ACID compliance for data integrity
- Cost-effective open-source solution

**Authentication - JWT:**
- Stateless authentication enables horizontal scaling
- Self-contained tokens reduce server-side storage
- Works well with RESTful APIs
- Supports distributed systems

---

## Layered Backend Architecture

### 5.1 N-Tier Architecture Overview

The backend follows a standard 4-tier layered architecture:

```
┌─────────────────────────────────────────────────┐
│          PRESENTATION LAYER                     │
│  (REST Controllers, Request/Response handling)  │
└────────────┬────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────┐
│        BUSINESS LOGIC LAYER                     │
│  (Services, Business Rules, Transactions)       │
└────────────┬────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────┐
│        PERSISTENCE LAYER                        │
│  (Repositories, Data Access Objects - JPA)      │
└────────────┬────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────┐
│          DATA LAYER                             │
│  (MySQL Database, Caching Layer)                │
└─────────────────────────────────────────────────┘
```

### 5.2 Presentation Layer (Controllers)

**Responsibilities:**
- Handle incoming HTTP requests
- Validate request parameters and headers
- Delegate business logic to service layer
- Transform service responses to HTTP responses
- Handle HTTP status codes and error responses

**Key Components:**
- `AuthController` - User registration, login, token refresh
- `ExpenseController` - CRUD operations for expenses
- `CategoryController` - Category management
- `BudgetController` - Budget operations
- `ReportController` - Analytics and reports
- `UserController` - User profile management
- `GlobalExceptionHandler` - Centralized error handling

**Example Controller Structure:**
```java
@RestController
@RequestMapping("/api/v1/expenses")
@RequiredArgsConstructor
public class ExpenseController {
    
    private final ExpenseService expenseService;
    private final ExpenseMapper expenseMapper;
    
    @GetMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Page<ExpenseDTO>> getExpenses(
            @PageableDefault(size = 20) Pageable pageable,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate) {
        
        Page<Expense> expenses = expenseService.getExpenses(pageable, category, startDate, endDate);
        return ResponseEntity.ok(expenses.map(expenseMapper::toDTO));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<ExpenseDTO> createExpense(@Valid @RequestBody CreateExpenseDTO dto) {
        Expense expense = expenseService.createExpense(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(expenseMapper.toDTO(expense));
    }
}
```

### 5.3 Business Logic Layer (Services)

**Responsibilities:**
- Implement business rules and logic
- Coordinate between controllers and repositories
- Handle transactions and data consistency
- Implement caching strategies
- Execute validation logic beyond HTTP constraints
- Implement authorization rules

**Key Components:**
- `AuthenticationService` - User authentication logic
- `ExpenseService` - Expense operations and business rules
- `BudgetService` - Budget calculations and alerts
- `CategoryService` - Category management
- `ReportService` - Analytics calculations
- `NotificationService` - Email and in-app notifications
- `UserService` - User management

**Example Service Structure:**
```java
@Service
@RequiredArgsConstructor
@Transactional
public class ExpenseService {
    
    private final ExpenseRepository expenseRepository;
    private final CategoryRepository categoryRepository;
    private final BudgetService budgetService;
    private final NotificationService notificationService;
    private final CacheManager cacheManager;
    
    @Transactional(readOnly = true)
    @Cacheable(value = "expenses", key = "#userId + '_' + #month")
    public List<Expense> getMonthlyExpenses(Long userId, YearMonth month) {
        return expenseRepository.findByUserIdAndMonth(userId, month);
    }
    
    public Expense createExpense(CreateExpenseDTO dto) {
        // Validate expense
        Category category = categoryRepository.findById(dto.getCategoryId())
            .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        
        // Create expense
        Expense expense = new Expense();
        expense.setAmount(dto.getAmount());
        expense.setCategory(category);
        expense.setDescription(dto.getDescription());
        expense.setDate(dto.getDate());
        
        Expense saved = expenseRepository.save(expense);
        
        // Check budget and send alerts
        budgetService.checkBudgetAlerts(expense.getUserId(), category.getId());
        
        // Clear cache
        cacheManager.getCache("expenses").clear();
        
        return saved;
    }
}
```

### 5.4 Persistence Layer (Repositories)

**Responsibilities:**
- Abstract database access logic
- Provide CRUD operations
- Execute custom queries
- Handle database-specific operations
- Implement query caching

**Key Components:**
- `UserRepository extends JpaRepository<User, Long>`
- `ExpenseRepository extends JpaRepository<Expense, Long>`
- `CategoryRepository extends JpaRepository<Category, Long>`
- `BudgetRepository extends JpaRepository<Budget, Long>`
- `AuditLogRepository extends JpaRepository<AuditLog, Long>`

**Example Repository Structure:**
```java
@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {
    
    Page<Expense> findByUserId(Long userId, Pageable pageable);
    
    List<Expense> findByUserIdAndCategoryId(Long userId, Long categoryId);
    
    @Query("SELECT e FROM Expense e WHERE e.userId = :userId " +
           "AND e.date BETWEEN :startDate AND :endDate")
    List<Expense> findExpensesByDateRange(
            @Param("userId") Long userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    @Query(value = "SELECT DATE(e.date) as date, SUM(e.amount) as total " +
                   "FROM expenses e WHERE e.user_id = :userId " +
                   "GROUP BY DATE(e.date) ORDER BY date DESC",
           nativeQuery = true)
    List<DailySpendingDTO> getDailySpending(@Param("userId") Long userId);
}
```

### 5.5 Data Layer (JPA Entities & Database)

**Responsibilities:**
- Define entity relationships
- Manage database schema
- Implement ORM mappings
- Handle lazy/eager loading strategies

**Key Entities:**
- `User` - User accounts and authentication
- `Expense` - Individual expense records
- `Category` - Expense categories
- `Budget` - Monthly budget limits
- `AuditLog` - Action audit trail

---

## Frontend Architecture

### 6.1 React Component Structure

The frontend follows a component-based architecture with clear separation:

```
src/
├── pages/                 # Page-level components
│   ├── Dashboard
│   ├── ExpenseList
│   ├── Login
│   ├── Register
│   ├── Reports
│   └── Settings
├── components/            # Reusable UI components
│   ├── Forms
│   ├── Cards
│   ├── Charts
│   ├── Navigation
│   └── Common
├── store/                 # Redux state management
│   ├── slices
│   ├── actions
│   └── selectors
├── services/              # API communication
│   ├── api.js
│   ├── authService.js
│   ├── expenseService.js
│   └── reportService.js
├── hooks/                 # Custom React hooks
│   ├── useAuth.js
│   ├── useFetch.js
│   └── useDebounce.js
├── utils/                 # Utility functions
│   ├── formatters.js
│   ├── validators.js
│   └── constants.js
├── styles/                # CSS/SCSS files
├── App.jsx
└── index.jsx
```

### 6.2 Component Hierarchy

```
App
├── AuthRouter
│   ├── LoginPage
│   ├── RegisterPage
│   └── PasswordReset
└── ProtectedRouter
    ├── Layout
    │   ├── Header
    │   ├── Sidebar
    │   └── Content
    │       ├── Dashboard
    │       │   ├── OverviewCards
    │       │   ├── RecentExpenses
    │       │   └── BudgetStatus
    │       ├── ExpenseManagement
    │       │   ├── ExpenseList
    │       │   ├── ExpenseForm
    │       │   └── ExpenseDetail
    │       ├── BudgetManagement
    │       │   ├── BudgetList
    │       │   └── BudgetForm
    │       ├── Reports
    │       │   ├── MonthlyReport
    │       │   ├── TrendAnalysis
    │       │   └── ComparisonReport
    │       └── Settings
    │           ├── ProfileSettings
    │           ├── NotificationPreferences
    │           └── AccountSettings
    └── Footer
```

### 6.3 State Management (Redux)

```
Redux Store
│
├── authSlice
│   ├── state: { user, token, isAuthenticated, loading }
│   ├── actions: { login, logout, register, refreshToken }
│   └── selectors: { selectUser, selectToken, selectIsAuthenticated }
│
├── expenseSlice
│   ├── state: { expenses, loading, filter, pagination }
│   ├── actions: { fetchExpenses, createExpense, updateExpense, deleteExpense }
│   └── selectors: { selectExpenses, selectFiltered, selectByCategory }
│
├── budgetSlice
│   ├── state: { budgets, alerts, loading }
│   ├── actions: { fetchBudgets, setBudget, updateBudget }
│   └── selectors: { selectBudgets, selectAlerts }
│
└── uiSlice
    ├── state: { theme, notifications, loading }
    └── actions: { setTheme, showNotification, hideNotification }
```

### 6.4 HTTP Client Configuration

```javascript
// services/api.js
import axios from 'axios';
import store from '../store';
import { logout, refreshToken } from '../store/slices/authSlice';

const api = axios.create({
    baseURL: process.env.REACT_APP_API_URL,
    timeout: 10000,
});

// Request interceptor: Add JWT token to headers
api.interceptors.request.use(
    (config) => {
        const token = store.getState().auth.token;
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

// Response interceptor: Handle token refresh and errors
api.interceptors.response.use(
    (response) => response,
    async (error) => {
        const originalRequest = error.config;
        
        if (error.response?.status === 401 && !originalRequest._retry) {
            originalRequest._retry = true;
            try {
                const response = await api.post('/auth/refresh');
                store.dispatch(refreshToken(response.data.token));
                originalRequest.headers.Authorization = `Bearer ${response.data.token}`;
                return api(originalRequest);
            } catch (refreshError) {
                store.dispatch(logout());
                window.location.href = '/login';
                return Promise.reject(refreshError);
            }
        }
        return Promise.reject(error);
    }
);

export default api;
```

### 6.5 Custom Hooks

```javascript
// hooks/useAuth.js
export const useAuth = () => {
    const dispatch = useDispatch();
    const user = useSelector(selectUser);
    const isAuthenticated = useSelector(selectIsAuthenticated);
    
    const login = useCallback((email, password) => {
        return dispatch(loginAsync({ email, password }));
    }, [dispatch]);
    
    const logout = useCallback(() => {
        dispatch(logoutAction());
    }, [dispatch]);
    
    return { user, isAuthenticated, login, logout };
};

// hooks/useFetch.js
export const useFetch = (url, options = {}) => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    
    useEffect(() => {
        const fetchData = async () => {
            try {
                const response = await api.get(url, options);
                setData(response.data);
            } catch (err) {
                setError(err);
            } finally {
                setLoading(false);
            }
        };
        
        fetchData();
    }, [url, options]);
    
    return { data, loading, error };
};
```

---

## Module Breakdown

### 7.1 Authentication Module

**Components:**
- User registration and email verification
- Login with JWT token generation
- Token refresh mechanism
- Password reset functionality
- Session management

**API Endpoints:**
```
POST   /api/v1/auth/register           - Register new user
POST   /api/v1/auth/login              - User login
POST   /api/v1/auth/refresh            - Refresh JWT token
POST   /api/v1/auth/logout             - Logout user
POST   /api/v1/auth/verify-email       - Verify email address
POST   /api/v1/auth/password-reset     - Request password reset
PUT    /api/v1/auth/password-reset/{token} - Reset password with token
```

**Key Classes:**
- `AuthenticationService`
- `JwtTokenProvider`
- `JwtAuthenticationFilter`
- `AuthController`
- `User` (Entity)

### 7.2 Expense Management Module

**Components:**
- Create, read, update, delete expenses
- Expense filtering and sorting
- Bulk operations
- Receipt upload and management
- Expense search

**API Endpoints:**
```
GET    /api/v1/expenses              - List all expenses (paginated)
POST   /api/v1/expenses              - Create new expense
GET    /api/v1/expenses/{id}         - Get expense details
PUT    /api/v1/expenses/{id}         - Update expense
DELETE /api/v1/expenses/{id}         - Delete expense (soft)
POST   /api/v1/expenses/bulk-delete  - Bulk delete expenses
GET    /api/v1/expenses/export       - Export expenses (CSV/PDF)
POST   /api/v1/expenses/{id}/receipt - Upload receipt
```

**Key Classes:**
- `ExpenseService`
- `ExpenseRepository`
- `ExpenseController`
- `Expense` (Entity)
- `ExpenseDTO`
- `FileStorageService`

### 7.3 Category Management Module

**Components:**
- Predefined categories
- Custom category creation
- Category hierarchy (parent/child)
- Category-based statistics

**API Endpoints:**
```
GET    /api/v1/categories           - List all categories
POST   /api/v1/categories           - Create custom category
GET    /api/v1/categories/{id}      - Get category details
PUT    /api/v1/categories/{id}      - Update category
DELETE /api/v1/categories/{id}      - Delete category
GET    /api/v1/categories/stats     - Category spending statistics
```

**Key Classes:**
- `CategoryService`
- `CategoryRepository`
- `CategoryController`
- `Category` (Entity)
- `CategoryDTO`

### 7.4 Budget Management Module

**Components:**
- Monthly budget setting per category
- Budget tracking and progress monitoring
- Budget alerts at 75%, 90%, 100% thresholds
- Budget history and comparisons

**API Endpoints:**
```
GET    /api/v1/budgets/{month}           - Get budgets for month
POST   /api/v1/budgets                   - Create/Set budget
PUT    /api/v1/budgets/{id}              - Update budget
DELETE /api/v1/budgets/{id}              - Delete budget
GET    /api/v1/budgets/{id}/progress     - Get budget progress
GET    /api/v1/budgets/alerts            - Get budget alerts
POST   /api/v1/budgets/check-threshold   - Check threshold alerts
```

**Key Classes:**
- `BudgetService`
- `BudgetRepository`
- `BudgetAlertService`
- `BudgetController`
- `Budget` (Entity)
- `BudgetDTO`

### 7.5 Reports & Analytics Module

**Components:**
- Monthly spending summary
- Spending trend analysis (3, 6, 12 months)
- Period comparison reports
- Category-wise breakdown
- Daily spending patterns
- Recurring expense identification

**API Endpoints:**
```
GET    /api/v1/reports/summary              - Monthly summary
GET    /api/v1/reports/trends               - Spending trends
GET    /api/v1/reports/comparison           - Period comparison
GET    /api/v1/reports/category-breakdown   - Category-wise breakdown
GET    /api/v1/reports/daily-spending       - Daily spending patterns
GET    /api/v1/reports/recurring-expenses   - Identify recurring expenses
```

**Key Classes:**
- `ReportService`
- `ReportController`
- `ReportDTO`
- `AnalyticsCalculator`

### 7.6 Notification Module

**Components:**
- Email notifications for budget alerts
- In-app notifications
- Notification preferences management
- Notification scheduling

**API Endpoints:**
```
GET    /api/v1/notifications                 - Get user notifications
POST   /api/v1/notifications/preferences     - Update preferences
PUT    /api/v1/notifications/{id}/read       - Mark as read
DELETE /api/v1/notifications/{id}            - Delete notification
```

**Key Classes:**
- `NotificationService`
- `EmailService`
- `NotificationRepository`
- `Notification` (Entity)

### 7.7 User Management Module

**Components:**
- User profile management
- Account settings
- Password change
- Account deletion request
- Data export

**API Endpoints:**
```
GET    /api/v1/users/profile                - Get user profile
PUT    /api/v1/users/profile                - Update profile
PUT    /api/v1/users/password               - Change password
GET    /api/v1/users/preferences            - Get preferences
PUT    /api/v1/users/preferences            - Update preferences
POST   /api/v1/users/export-data            - Export user data
POST   /api/v1/users/delete-account         - Request account deletion
```

**Key Classes:**
- `UserService`
- `UserRepository`
- `UserController`
- `User` (Entity)
- `UserDTO`

---

## Request Flow

### 8.1 Typical Request/Response Cycle

```
┌─────────────────────────────────────────────────────────────────┐
│ CLIENT (React Application)                                      │
│                                                                  │
│  1. User Action (e.g., click "Add Expense")                    │
│     ↓                                                           │
│  2. Dispatch Redux Action                                      │
│     ↓                                                           │
│  3. API Service prepares request                              │
│     ↓                                                           │
│  4. HTTP Interceptor adds JWT token to Authorization header   │
│     ↓                                                           │
│  5. Axios sends HTTPS POST request                            │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ POST /api/v1/expenses
             │ Headers: { Authorization: "Bearer JWT_TOKEN", ... }
             │ Body: { amount, category, date, description }
             │
             ↓
┌─────────────────────────────────────────────────────────────────┐
│ SERVER (Spring Boot Application)                                │
│                                                                  │
│  6. Request reaches Load Balancer/Nginx → Routes to app instance│
│     ↓                                                           │
│  7. JwtAuthenticationFilter intercepts request                 │
│     - Extracts JWT token from Authorization header            │
│     - Validates token signature                               │
│     - Creates Authentication object                           │
│     - Sets SecurityContext                                    │
│     ↓                                                           │
│  8. Spring Security evaluates @PreAuthorize("hasRole('USER')")|
│     ↓                                                           │
│  9. ExpenseController.createExpense() receives request        │
│     - @Valid validates RequestBody                           │
│     - Extracts userId from SecurityContext                   │
│     ↓                                                           │
│  10. @Transactional begins database transaction               │
│      ↓                                                         │
│  11. ExpenseService.createExpense() executes business logic  │
│      - Validates expense data                                │
│      - Fetches Category from CategoryRepository              │
│      - Creates Expense entity                                │
│      - Saves to database via ExpenseRepository               │
│      - Checks budget alerts via BudgetService               │
│      - Triggers notification if budget exceeded             │
│      - Clears cache (if using Redis)                        │
│      ↓                                                         │
│  12. ExpenseRepository.save() executes Hibernate ORM         │
│      - Generates SQL INSERT statement                        │
│      - Executes via JDBC to MySQL                            │
│      ↓                                                         │
│  13. MySQL processes transaction                              │
│      - Validates constraints                                 │
│      - Writes to InnoDB buffer pool                          │
│      - Returns inserted record with ID                       │
│      ↓                                                         │
│  14. Transaction commits                                      │
│      ↓                                                         │
│  15. ExpenseMapper converts Entity to DTO                    │
│      ↓                                                         │
│  16. Controller returns ResponseEntity                        │
│      - Status: 201 Created                                   │
│      - Body: { id, amount, category, ... }                  │
│      - Headers: { Location: /api/v1/expenses/{id} }         │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ HTTP 201 Created
             │ Body: { expense data }
             │
             ↓
┌─────────────────────────────────────────────────────────────────┐
│ CLIENT (React Application)                                      │
│                                                                  │
│  17. Response received by Axios                                │
│      ↓                                                         │
│  18. Response Interceptor processes response                  │
│      - Handles any errors                                    │
│      - Updates auth token if needed                         │
│      ↓                                                         │
│  19. Promise resolves in component                            │
│      ↓                                                         │
│  20. Redux action updates state                               │
│      - Adds new expense to expenseSlice                      │
│      - Updates UI state (loading = false)                   │
│      ↓                                                         │
│  21. React re-renders component                               │
│      - Displays new expense in list                          │
│      - Shows success notification                           │
│      ↓                                                         │
│  22. User sees updated UI                                     │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Error Handling Flow

```
┌──────────────────────────────┐
│ Client sends request         │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ Server receives request      │
└──────────────┬───────────────┘
               ↓
       ┌───────────────────┐
       │ Exception occurs? │
       └───┬───────────────┘
           │
       Yes │
           ↓
   ┌───────────────────────────────────────┐
   │ Exception caught by:                  │
   │ - @ControllerAdvice                   │
   │ - GlobalExceptionHandler              │
   └───┬───────────────────────────────────┘
       │
       ├─→ ResourceNotFoundException (404)
       ├─→ UnauthorizedException (401)
       ├─→ ForbiddenException (403)
       ├─→ ValidationException (400)
       ├─→ DatabaseException (500)
       └─→ GenericException (500)
           │
           ↓
   ┌──────────────────────────────────────┐
   │ Convert to ErrorResponse:            │
   │ - status: HTTP status code           │
   │ - timestamp: current time            │
   │ - message: error message             │
   │ - path: request path                 │
   │ - errors: field-level errors (if any)│
   └───┬──────────────────────────────────┘
       │
       ↓
   ┌──────────────────────────────────────┐
   │ Return JSON error response           │
   │ with appropriate HTTP status         │
   └───┬──────────────────────────────────┘
       │
       ↓
   ┌──────────────────────────────────────┐
   │ Client receives error response       │
   │ - Response interceptor processes     │
   │ - Redux action updates state         │
   │ - UI displays error message          │
   └──────────────────────────────────────┘
```

---

## Authentication Flow (JWT)

### 9.1 JWT Token Generation & Validation

```
┌─────────────────────────────────────────────────────────────────┐
│ REGISTRATION & LOGIN FLOW                                       │
└─────────────────────────────────────────────────────────────────┘

User Registration:
  1. User enters email and password
  2. Client sends POST /api/v1/auth/register
  3. Server validates email format and password strength
  4. Server hashes password using BCrypt (with salt)
  5. Server creates User entity
  6. Server generates verification email token (short-lived)
  7. Server sends verification email with link
  8. User clicks email verification link
  9. Server validates token and marks email as verified
  10. User can now login

User Login:
  1. User enters email and password
  2. Client sends POST /api/v1/auth/login
  3. Server retrieves User by email from database
  4. Server compares provided password with stored BCrypt hash
  5. Password matches → proceed; mismatch → return 401
  6. Server generates JWT tokens:
     
     ACCESS_TOKEN:
     - Header: { alg: "HS512", typ: "JWT" }
     - Payload: {
         sub: userId,
         email: user.email,
         roles: ["ROLE_USER"],
         iat: issuedAt,
         exp: expirationTime (24 hours)
       }
     - Signature: HMAC-SHA512(header.payload, SECRET_KEY)
     
     REFRESH_TOKEN:
     - Shorter payload (just userId)
     - Longer expiration (7 days)
  
  7. Server returns both tokens in response
  8. Client stores tokens:
     - ACCESS_TOKEN: Memory or localStorage
     - REFRESH_TOKEN: httpOnly cookie (more secure)
  9. User is logged in
```

### 9.2 JWT Token Usage in Requests

```
┌─────────────────────────────────────────────────────────────────┐
│ PROTECTED REQUEST FLOW                                          │
└─────────────────────────────────────────────────────────────────┘

Authenticated Request:
  1. Client makes request to protected endpoint
  2. HTTP Interceptor extracts ACCESS_TOKEN
  3. Adds to Authorization header:
     Authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9...
  4. Request sent to server

Server Receives Request:
  1. JwtAuthenticationFilter intercepts request
  2. Extracts token from Authorization header
  3. Validates token:
     - Checks signature using SECRET_KEY
     - Verifies expiration time
     - Verifies token is not blacklisted
  4. Token valid:
     - Extracts claims (userId, roles, etc.)
     - Creates Authentication object
     - Sets in SecurityContext
  5. Token invalid/expired:
     - Returns 401 Unauthorized
     - Client catches error
     - Attempts to refresh token (see Token Refresh Flow)

Endpoint Execution:
  1. Controller accesses SecurityContext
  2. Retrieves userId and roles
  3. Spring Security applies @PreAuthorize checks
  4. Endpoint processes with authenticated user context
```

### 9.3 Token Refresh Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ TOKEN REFRESH FLOW                                              │
└─────────────────────────────────────────────────────────────────┘

Scenario: ACCESS_TOKEN expired, REFRESH_TOKEN valid

  1. Client makes request with expired ACCESS_TOKEN
  2. Server returns 401 Unauthorized
  3. Response interceptor catches 401
  4. Checks if REFRESH_TOKEN exists
  5. Sends POST /api/v1/auth/refresh with REFRESH_TOKEN
  
  Server validates REFRESH_TOKEN:
  - Checks signature and expiration
  - Retrieves userId from token claims
  - Verifies user still exists and is active
  
  Server generates new tokens:
  - New ACCESS_TOKEN (24 hour expiration)
  - New REFRESH_TOKEN (7 day expiration)
  
  6. Server returns new tokens
  7. Client updates stored tokens
  8. Response interceptor retries original request with new token
  9. Original request completes successfully
  
  Scenario: REFRESH_TOKEN also expired
  - Server returns 401 on refresh attempt
  - Client detects refresh failure
  - Client redirects to login page
  - User must login again
```

### 9.4 Logout Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ LOGOUT FLOW                                                     │
└─────────────────────────────────────────────────────────────────┘

  1. User clicks logout button
  2. Client sends POST /api/v1/auth/logout with ACCESS_TOKEN
  3. Server receives logout request
  4. Server adds token to blacklist (Redis):
     - Key: token_blacklist:{token_hash}
     - Value: true
     - TTL: token.expiration_time (auto-deletes when expires)
  5. Server clears user session data
  6. Server returns 200 OK
  7. Client clears stored tokens from memory
  8. Client clears cookies
  9. Client redirects to login page
  
  For subsequent requests:
  - Even if user tries to use old token
  - JwtAuthenticationFilter checks blacklist
  - Token is blacklisted → returns 401
  - User must login again
```

### 9.5 JWT Structure Example

```
Header.Payload.Signature

Header (Base64URL encoded):
{
  "alg": "HS512",
  "typ": "JWT"
}

Payload (Base64URL encoded):
{
  "sub": "12345",              // Subject (userId)
  "email": "user@example.com",
  "name": "John Doe",
  "roles": ["ROLE_USER"],
  "iat": 1672531200,           // Issued At
  "exp": 1672617600,           // Expiration Time (24 hours later)
  "iss": "expense-tracker",    // Issuer
  "aud": "expense-tracker"     // Audience
}

Signature (HMAC-SHA512):
HMACSHA512(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)

Complete Token:
eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NSIsImVtYWlsIjoidXNlckBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsInJvbGVzIjpbIlJPTEVfVVNFUiJdLCJpYXQiOjE2NzI1MzEyMDAsImV4cCI6MTY3MjYxNzYwMCwiaXNzIjoiZXhwZW5zZS10cmFja2VyIiwiYXVkIjoiZXhwZW5zZS10cmFja2VyIn0.
kWc3lAi4Z...
```

---

## Database Interaction Flow

### 10.1 CRUD Operations Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ CREATE (INSERT) OPERATION                                       │
└─────────────────────────────────────────────────────────────────┘

Controller.createExpense(ExpenseDTO)
  ↓
ExpenseService.createExpense(ExpenseDTO)
  │
  ├─ Validate input (amount > 0, date valid, category exists)
  │
  ├─ Fetch related entities:
  │  - Category category = categoryRepository.findById(categoryId)
  │  - User user = userRepository.findById(userId)
  │
  ├─ Create new Entity:
  │  - Expense expense = new Expense()
  │  - expense.setAmount(amount)
  │  - expense.setCategory(category)
  │  - expense.setUser(user)
  │  - expense.setCreatedAt(now)
  │
  └─ Persist to database:
     ↓
ExpenseRepository.save(expense)
  │
  ├─ Hibernate ORM converts entity to SQL
  ├─ Generates: INSERT INTO expenses (...) VALUES (...)
  │
  └─ JPA executes via JDBC
     ↓
MySQL Database
  │
  ├─ Validates constraints (NOT NULL, FOREIGN KEY)
  ├─ Checks indexes
  ├─ Writes to InnoDB buffer pool
  ├─ Executes binary log (for replication)
  ├─ Returns auto-generated ID
  │
  └─ Returns saved entity with ID
     ↑
Controller returns ResponseEntity<ExpenseDTO>


┌─────────────────────────────────────────────────────────────────┐
│ READ (SELECT) OPERATION                                         │
└─────────────────────────────────────────────────────────────────┘

Controller.getExpenses(pageable, filters)
  ↓
ExpenseService.getExpenses(pageable, category, startDate, endDate)
  │
  ├─ Check cache (if Redis enabled)
  │  - If cache hit: return cached data
  │
  └─ Query database:
     ↓
ExpenseRepository.findByUserIdAndFilters(userId, filters)
  │
  ├─ Generates JPA Criteria Query or JPQL
  ├─ Converts to SQL:
  │  SELECT * FROM expenses
  │  WHERE user_id = ? AND category_id = ?
  │  AND date BETWEEN ? AND ?
  │  ORDER BY date DESC
  │  LIMIT 20 OFFSET 0
  │
  └─ JPA executes via JDBC
     ↓
MySQL Database
  │
  ├─ Executes query
  ├─ Uses indexes for fast lookup
  ├─ Applies filters and pagination
  │
  └─ Returns result set
     ↑
Hibernate maps results to Entity objects
  │
  └─ Cache result in Redis (if enabled)
     ↑
Service returns List<Expense>
  ↓
Mapper converts Entities to DTOs
  ↓
Controller returns ResponseEntity<Page<ExpenseDTO>>


┌─────────────────────────────────────────────────────────────────┐
│ UPDATE (MODIFY) OPERATION                                       │
└─────────────────────────────────────────────────────────────────┘

Controller.updateExpense(id, ExpenseDTO)
  ↓
ExpenseService.updateExpense(id, ExpenseDTO)
  │
  ├─ Fetch existing entity:
  │  - Expense existing = repository.findById(id)
  │  - If not found: throw ResourceNotFoundException
  │
  ├─ Update fields:
  │  - existing.setAmount(dto.getAmount())
  │  - existing.setCategory(...)
  │  - existing.setUpdatedAt(now)
  │
  └─ Persist changes:
     ↓
ExpenseRepository.save(existing)
  │
  ├─ Hibernate detects this is existing entity (has ID)
  ├─ Generates UPDATE SQL (not INSERT)
  ├─ UPDATE expenses SET amount=?, category_id=?, updated_at=? WHERE id=?
  │
  └─ JPA executes via JDBC
     ↓
MySQL Database
  │
  ├─ Updates row
  ├─ Updates indexes
  │
  └─ Returns updated entity
     ↑
Clear cache for this entity
  ↓
Controller returns ResponseEntity<ExpenseDTO>


┌─────────────────────────────────────────────────────────────────┐
│ DELETE (REMOVE) OPERATION                                       │
└─────────────────────────────────────────────────────────────────┘

Controller.deleteExpense(id)
  ↓
ExpenseService.deleteExpense(id)
  │
  ├─ Fetch existing entity:
  │  - Expense expense = repository.findById(id)
  │
  ├─ Soft delete (set is_deleted flag):
  │  - expense.setIsDeleted(true)
  │  - expense.setDeletedAt(now)
  │
  └─ Persist changes:
     ↓
ExpenseRepository.save(expense)
  │
  ├─ Generates: UPDATE expenses SET is_deleted=1, deleted_at=? WHERE id=?
  │
  └─ JPA executes via JDBC
     ↓
MySQL Database
  │
  ├─ Updates row
  │
  └─ Record still exists (not purged)
     ↑
Clear cache
  ↓
Controller returns ResponseEntity<NoContent>

Note: Hard delete only after retention period (compliance requirement)
```

### 10.2 Transaction Management

```
┌─────────────────────────────────────────────────────────────────┐
│ TRANSACTIONAL OPERATION                                         │
└─────────────────────────────────────────────────────────────────┘

@Transactional
public Expense createExpenseWithBudgetCheck(CreateExpenseDTO dto) {
  
  START TRANSACTION
  │
  ├─ 1. Create Expense
  │    - repository.save(expense)
  │
  ├─ 2. Check Budget
  │    - budgetService.checkBudgetAlerts(...)
  │    - If alert: create Notification
  │
  ├─ 3. Update Cache
  │    - cacheManager.getCache("expenses").clear()
  │
  ├─ All operations succeed?
  │  └─→ YES: COMMIT
  │      - All changes written to database
  │      - Durable and visible to other transactions
  │
  └─ Any error occurs?
     └─→ YES: ROLLBACK
         - All changes reverted
         - Database unchanged
         - Exception propagated to caller

Database Isolation Levels:
- READ_UNCOMMITTED: Can read uncommitted changes (dirty reads)
- READ_COMMITTED: Default - only read committed data (good balance)
- REPEATABLE_READ: Repeated reads return same data (prevents non-repeatable reads)
- SERIALIZABLE: Highest isolation - concurrent transactions serialized

Spring's default: READ_COMMITTED
```

### 10.3 N+1 Query Problem & Solutions

```
┌─────────────────────────────────────────────────────────────────┐
│ PROBLEM: N+1 QUERIES                                            │
└─────────────────────────────────────────────────────────────────┘

// Problematic code:
List<Expense> expenses = expenseRepository.findByUserId(userId);

// This causes:
// Query 1: SELECT * FROM expenses WHERE user_id = 1
// Query 2-N: For each expense, SELECT * FROM categories WHERE id = ?
// Total: 1 + N queries (inefficient!)

┌─────────────────────────────────────────────────────────────────┐
│ SOLUTION 1: JOIN FETCH (EAGER LOADING)                          │
└─────────────────────────────────────────────────────────────────┘

@Query("SELECT DISTINCT e FROM Expense e " +
       "JOIN FETCH e.category c " +
       "WHERE e.userId = :userId")
List<Expense> findByUserIdWithCategory(@Param("userId") Long userId);

// Result: Only 2 queries (1 for expenses + categories joined)

┌─────────────────────────────────────────────────────────────────┐
│ SOLUTION 2: EAGER LOADING IN ENTITY                             │
└─────────────────────────────────────────────────────────────────┘

@Entity
public class Expense {
  @ManyToOne(fetch = FetchType.EAGER)
  private Category category;
}

// Hibernate automatically fetches category when loading expense
// But be careful: can impact performance if not used selectively

┌─────────────────────────────────────────────────────────────────┐
│ SOLUTION 3: DTO PROJECTION                                      │
└─────────────────────────────────────────────────────────────────┘

@Query("SELECT new ExpenseDTO(e.id, e.amount, e.date, c.name) " +
       "FROM Expense e JOIN e.category c " +
       "WHERE e.userId = :userId")
List<ExpenseDTO> findByUserIdDTO(@Param("userId") Long userId);

// Only selects needed fields, reduces data transfer
```

---

## Folder Structure

### 11.1 Backend Folder Structure

```
smart-expense-tracker-backend/
│
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── expensetracker/
│   │   │           ├── SmartExpenseTrackerApplication.java
│   │   │           │
│   │   │           ├── config/
│   │   │           │   ├── SecurityConfig.java           # Spring Security configuration
│   │   │           │   ├── WebConfig.java                # CORS, converters
│   │   │           │   ├── CacheConfig.java              # Redis cache configuration
│   │   │           │   ├── JpaConfig.java                # JPA/Hibernate config
│   │   │           │   └── OpenApiConfig.java            # Swagger/OpenAPI config
│   │   │           │
│   │   │           ├── controller/
│   │   │           │   ├── AuthController.java           # Authentication endpoints
│   │   │           │   ├── ExpenseController.java        # Expense CRUD endpoints
│   │   │           │   ├── CategoryController.java       # Category endpoints
│   │   │           │   ├── BudgetController.java         # Budget endpoints
│   │   │           │   ├── ReportController.java         # Reports endpoints
│   │   │           │   ├── UserController.java           # User profile endpoints
│   │   │           │   └── GlobalExceptionHandler.java   # Centralized error handling
│   │   │           │
│   │   │           ├── service/
│   │   │           │   ├── AuthenticationService.java    # Authentication logic
│   │   │           │   ├── ExpenseService.java           # Expense business logic
│   │   │           │   ├── CategoryService.java          # Category management
│   │   │           │   ├── BudgetService.java            # Budget calculations
│   │   │           │   ├── BudgetAlertService.java       # Budget notifications
│   │   │           │   ├── ReportService.java            # Analytics & reports
│   │   │           │   ├── NotificationService.java      # Email/notifications
│   │   │           │   ├── UserService.java              # User management
│   │   │           │   ├── EmailService.java             # Email sending
│   │   │           │   ├── FileStorageService.java       # Receipt file handling
│   │   │           │   └── CacheService.java             # Cache operations
│   │   │           │
│   │   │           ├── repository/
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── ExpenseRepository.java        # Custom queries
│   │   │           │   ├── CategoryRepository.java
│   │   │           │   ├── BudgetRepository.java
│   │   │           │   ├── NotificationRepository.java
│   │   │           │   └── AuditLogRepository.java
│   │   │           │
│   │   │           ├── entity/
│   │   │           │   ├── User.java
│   │   │           │   ├── Expense.java
│   │   │           │   ├── Category.java
│   │   │           │   ├── Budget.java
│   │   │           │   ├── Notification.java
│   │   │           │   ├── AuditLog.java
│   │   │           │   └── BaseEntity.java               # Abstract base class
│   │   │           │
│   │   │           ├── dto/
│   │   │           │   ├── request/
│   │   │           │   │   ├── CreateExpenseDTO.java
│   │   │           │   │   ├── UpdateExpenseDTO.java
│   │   │           │   │   ├── CreateBudgetDTO.java
│   │   │           │   │   ├── LoginDTO.java
│   │   │           │   │   ├── RegisterDTO.java
│   │   │           │   │   └── ...
│   │   │           │   ├── response/
│   │   │           │   │   ├── ExpenseDTO.java
│   │   │           │   │   ├── BudgetDTO.java
│   │   │           │   │   ├── AuthResponseDTO.java
│   │   │           │   │   ├── ErrorResponseDTO.java
│   │   │           │   │   └── ...
│   │   │           │   └── ReportDTO.java
│   │   │           │
│   │   │           ├── security/
│   │   │           │   ├── JwtTokenProvider.java         # JWT generation & validation
│   │   │           │   ├── JwtAuthenticationFilter.java  # Request interceptor
│   │   │           │   ├── CustomUserDetailsService.java # User authentication
│   │   │           │   ├── JwtAuthenticationEntryPoint.java  # Unauthorized handler
│   │   │           │   └── JwtAccessDeniedHandler.java   # Forbidden handler
│   │   │           │
│   │   │           ├── mapper/
│   │   │           │   ├── ExpenseMapper.java           # Entity ↔ DTO conversion
│   │   │           │   ├── UserMapper.java
│   │   │           │   ├── CategoryMapper.java
│   │   │           │   └── BudgetMapper.java
│   │   │           │
│   │   │           ├── exception/
│   │   │           │   ├── ResourceNotFoundException.java
│   │   │           │   ├── UnauthorizedException.java
│   │   │           │   ├── ForbiddenException.java
│   │   │           │   ├── ValidationException.java
│   │   │           │   ├── DatabaseException.java
│   │   │           │   └── BaseException.java
│   │   │           │
│   │   │           ├── util/
│   │   │           │   ├── DateUtil.java
│   │   │           │   ├── CurrencyConverter.java
│   │   │           │   ├── ValidationUtil.java
│   │   │           │   ├── SecurityUtil.java            # Get current user
│   │   │           │   └── Constants.java
│   │   │           │
│   │   │           └── listener/
│   │   │               ├── AuditLoggingListener.java    # JPA event listeners
│   │   │               └── EntityChangeListener.java
│   │   │
│   │   └── resources/
│   │       ├── application.yml                # Main configuration
│   │       ├── application-dev.yml            # Development profile
│   │       ├── application-prod.yml           # Production profile
│   │       ├── application-test.yml           # Test profile
│   │       ├── db/
│   │       │   └── migration/                 # Flyway migrations
│   │       │       ├── V1__initial_schema.sql
│   │       │       ├── V2__add_audit_logs.sql
│   │       │       └── ...
│   │       ├── templates/
│   │       │   └── emails/
│   │       │       ├── verification.html
│   │       │       ├── password-reset.html
│   │       │       └── budget-alert.html
│   │       └── logback-spring.xml            # Logging configuration
│   │
│   └── test/
│       ├── java/
│       │   └── com/expensetracker/
│       │       ├── controller/
│       │       │   ├── AuthControllerTest.java
│       │       │   └── ExpenseControllerTest.java
│       │       ├── service/
│       │       │   ├── ExpenseServiceTest.java
│       │       │   ├── BudgetServiceTest.java
│       │       │   └── ...
│       │       ├── repository/
│       │       │   └── ExpenseRepositoryTest.java
│       │       └── integration/
│       │           └── ExpenseIntegrationTest.java
│       │
│       └── resources/
│           └── application-test.yml
│
├── pom.xml                                  # Maven dependencies
├── Dockerfile                               # Docker image
├── docker-compose.yml                       # Local development stack
├── .github/workflows/
│   ├── build.yml                            # CI/CD pipeline
│   └── deploy.yml
├── .gitignore
└── README.md

Key Directory Meanings:

config/        → Application-wide configuration beans
controller/    → REST API endpoints and request handling
service/       → Business logic and orchestration
repository/    → Data access layer (JPA interfaces)
entity/        → JPA entity classes representing database tables
dto/           → Data Transfer Objects for API contracts
security/      → Authentication, authorization, JWT handling
mapper/        → Entity to DTO conversion
exception/     → Custom exception classes
util/          → Utility and helper classes
listener/      → JPA entity listeners for audit logging
```

### 11.2 Frontend Folder Structure

```
smart-expense-tracker-frontend/
│
├── public/
│   ├── index.html
│   ├── favicon.ico
│   └── manifest.json
│
├── src/
│   ├── pages/
│   │   ├── Dashboard.jsx                  # Main dashboard page
│   │   ├── ExpenseList.jsx               # View all expenses
│   │   ├── ExpenseForm.jsx               # Add/Edit expense
│   │   ├── ExpenseDetail.jsx             # Single expense details
│   │   ├── Login.jsx                     # Login page
│   │   ├── Register.jsx                  # Registration page
│   │   ├── PasswordReset.jsx             # Password reset
│   │   ├── Reports.jsx                   # Analytics & reports
│   │   ├── BudgetManagement.jsx          # Budget configuration
│   │   ├── Settings.jsx                  # User settings
│   │   └── NotFound.jsx                  # 404 page
│   │
│   ├── components/
│   │   ├── Layout/
│   │   │   ├── Layout.jsx                # Main layout wrapper
│   │   │   ├── Header.jsx                # Top navigation bar
│   │   │   ├── Sidebar.jsx               # Side navigation
│   │   │   └── Footer.jsx                # Footer
│   │   │
│   │   ├── Forms/
│   │   │   ├── ExpenseForm.jsx           # Expense CRUD form
│   │   │   ├── BudgetForm.jsx            # Budget form
│   │   │   ├── LoginForm.jsx             # Login form
│   │   │   ├── RegisterForm.jsx          # Registration form
│   │   │   └── FilterForm.jsx            # Expense filters
│   │   │
│   │   ├── Cards/
│   │   │   ├── OverviewCard.jsx          # Dashboard summary cards
│   │   │   ├── ExpenseCard.jsx           # Expense list item
│   │   │   ├── BudgetCard.jsx            # Budget status card
│   │   │   └── StatCard.jsx              # Statistics card
│   │   │
│   │   ├── Charts/
│   │   │   ├── BarChart.jsx              # Category spending chart
│   │   │   ├── LineChart.jsx             # Trend over time
│   │   │   ├── PieChart.jsx              # Category breakdown
│   │   │   └── ChartContainer.jsx        # Wrapper component
│   │   │
│   │   ├── Tables/
│   │   │   ├── ExpenseTable.jsx          # Expenses list table
│   │   │   ├── BudgetTable.jsx           # Budgets table
│   │   │   └── DataTable.jsx             # Generic table component
│   │   │
│   │   ├── Navigation/
│   │   │   ├── Navbar.jsx
│   │   │   ├── BreadCrumb.jsx
│   │   │   └── Tabs.jsx
│   │   │
│   │   ├── Common/
│   │   │   ├── Button.jsx
│   │   │   ├── Modal.jsx
│   │   │   ├── Loader.jsx
│   │   │   ├── Alert.jsx
│   │   │   ├── Pagination.jsx
│   │   │   ├── ConfirmDialog.jsx
│   │   │   └── EmptyState.jsx
│   │   │
│   │   ├── Auth/
│   │   │   ├── ProtectedRoute.jsx        # Private route wrapper
│   │   │   └── AuthGuard.jsx             # Auth check component
│   │   │
│   │   └── Notifications/
│   │       ├── Toast.jsx                 # Toast notifications
│   │       ├── ToastContainer.jsx
│   │       └── BudgetAlert.jsx           # Budget alert component
│   │
│   ├── store/
│   │   ├── store.js                      # Redux store configuration
│   │   ├── hooks.js                      # Redux hooks (useAppDispatch, etc.)
│   │   │
│   │   └── slices/
│   │       ├── authSlice.js              # Authentication state
│   │       ├── expenseSlice.js           # Expenses state
│   │       ├── budgetSlice.js            # Budget state
│   │       ├── categorySlice.js          # Categories state
│   │       ├── reportSlice.js            # Reports state
│   │       ├── notificationSlice.js      # Notifications state
│   │       └── uiSlice.js                # UI state (theme, modals)
│   │
│   ├── services/
│   │   ├── api.js                        # Axios instance & interceptors
│   │   ├── authService.js                # Authentication API calls
│   │   ├── expenseService.js             # Expense API calls
│   │   ├── budgetService.js              # Budget API calls
│   │   ├── categoryService.js            # Category API calls
│   │   ├── reportService.js              # Reports API calls
│   │   ├── userService.js                # User API calls
│   │   └── storageService.js             # LocalStorage operations
│   │
│   ├── hooks/
│   │   ├── useAuth.js                    # Authentication hook
│   │   ├── useFetch.js                   # Data fetching hook
│   │   ├── useForm.js                    # Form handling hook
│   │   ├── useDebounce.js                # Debounce hook
│   │   ├── usePagination.js              # Pagination hook
│   │   ├── useLocalStorage.js            # LocalStorage hook
│   │   └── useWindowSize.js              # Window resize hook
│   │
│   ├── utils/
│   │   ├── formatters.js                 # Date, currency formatting
│   │   ├── validators.js                 # Input validation
│   │   ├── constants.js                  # App constants
│   │   ├── errorHandler.js               # Error processing
│   │   ├── apiErrorHandler.js            # API error handling
│   │   ├── chartHelpers.js               # Chart data preparation
│   │   ├── dateHelpers.js                # Date utilities
│   │   └── storageKeys.js                # LocalStorage keys
│   │
│   ├── styles/
│   │   ├── index.css                     # Global styles
│   │   ├── variables.css                 # CSS variables (colors, fonts)
│   │   ├── components.css                # Component styles
│   │   ├── responsive.css                # Media queries
│   │   ├── animations.css                # Animations & transitions
│   │   └── tailwind.config.js             # Tailwind config (if using Tailwind)
│   │
│   ├── assets/
│   │   ├── images/
│   │   │   ├── logo.svg
│   │   │   ├── icons/
│   │   │   └── illustrations/
│   │   └── fonts/
│   │
│   ├── constants/
│   │   ├── api.js                        # API URLs & endpoints
│   │   ├── messages.js                   # User messages
│   │   ├── categories.js                 # Default categories
│   │   └── config.js                     # App configuration
│   │
│   ├── App.jsx                           # Root component
│   ├── App.css                           # App styles
│   ├── index.jsx                         # Entry point
│   └── index.css                         # Global styles
│
├── tests/
│   ├── components/
│   │   ├── ExpenseForm.test.jsx
│   │   ├── Dashboard.test.jsx
│   │   └── ...
│   ├── services/
│   │   ├── expenseService.test.js
│   │   └── ...
│   ├── store/
│   │   ├── expenseSlice.test.js
│   │   └── ...
│   └── utils/
│       ├── formatters.test.js
│       └── ...
│
├── .env                                   # Environment variables
├── .env.example                           # Example env file
├── .gitignore
├── package.json                           # NPM dependencies
├── package-lock.json
├── vite.config.js                         # Vite config (or webpack.config.js)
├── jest.config.js                         # Jest testing config
├── .eslintrc.json                         # ESLint config
├── .prettierrc                            # Prettier config
└── README.md

Key Directory Meanings:

pages/         → Full page components (routable)
components/    → Reusable UI components
store/         → Redux state management
services/      → API communication and external services
hooks/         → Custom React hooks
utils/         → Utility and helper functions
styles/        → Global and component styles
assets/        → Images, fonts, static files
tests/         → Unit and component tests
constants/     → App-wide constants and configuration
```

---

## Design Patterns

### 12.1 Architectural Patterns Used

| Pattern | Location | Purpose |
|---------|----------|---------|
| **MVC (Model-View-Controller)** | Backend Controllers → Services → Repositories | Separates concerns between data, business logic, and presentation |
| **Repository Pattern** | `repository/` package | Abstracts database access, enables unit testing |
| **Service Layer Pattern** | `service/` package | Centralizes business logic, promotes reusability |
| **Dependency Injection** | Spring Framework | Loose coupling, easier testing, flexible configuration |
| **DTO Pattern** | `dto/` package | Isolates entity model from API contracts |
| **Mapper Pattern** | `mapper/` package | Converts between entities and DTOs |
| **Factory Pattern** | Services, Utilities | Creates objects with complex logic |
| **Observer Pattern** | Event Listeners, Notifications | Decouples notification system from business logic |
| **Strategy Pattern** | File Storage, Export Formats | Different implementations of interface (CSV, PDF export) |
| **Template Method Pattern** | BaseEntity, BaseService | Defines algorithm skeleton in base class |
| **Proxy Pattern** | Spring AOP, Lazy Loading | Adds functionality to objects (transaction management, security) |
| **Singleton Pattern** | Spring Beans, Configuration | Ensures single instance of beans |
| **Container/IoC Pattern** | Spring Framework | Manages object lifecycle and dependencies |

### 12.2 Implementation Examples

#### Repository Pattern

```java
// Abstraction layer
public interface ExpenseRepository extends JpaRepository<Expense, Long> {
    List<Expense> findByUserId(Long userId);
    Page<Expense> findByUserIdAndCategoryId(Long userId, Long categoryId, Pageable pageable);
}

// Service uses repository, not direct database access
@Service
public class ExpenseService {
    private final ExpenseRepository repository;
    
    public List<Expense> getUserExpenses(Long userId) {
        return repository.findByUserId(userId);
    }
}

// Benefits:
// - Database implementation can be swapped
// - Easier to mock in tests
// - Centralized query logic
```

#### DTO Pattern

```java
// Entity (internal representation)
@Entity
public class Expense {
    private Long id;
    private BigDecimal amount;
    private String description;
    private Category category;
    private User user;
    private LocalDateTime createdAt;
}

// DTO (API contract)
public class ExpenseDTO {
    private Long id;
    private BigDecimal amount;
    private String description;
    private Long categoryId;
    private String categoryName;
}

// Benefits:
// - API contract independent from entity model
// - Can modify entity without breaking API
// - Control what fields are exposed
```

#### Factory Pattern

```java
// Factory creates appropriate strategy
@Service
public class ExportServiceFactory {
    
    public ExportStrategy getExportStrategy(ExportFormat format) {
        switch (format) {
            case CSV:
                return new CsvExportStrategy();
            case PDF:
                return new PdfExportStrategy();
            case EXCEL:
                return new ExcelExportStrategy();
            default:
                throw new IllegalArgumentException("Unknown format: " + format);
        }
    }
}

// Strategy interface
public interface ExportStrategy {
    byte[] export(List<Expense> expenses);
}

// Benefits:
// - Encapsulates object creation
// - Easy to add new export formats
// - Flexible and extensible
```

#### Observer Pattern

```java
// Event when budget alert occurs
public class BudgetAlertEvent extends ApplicationEvent {
    private final Long userId;
    private final BudgetAlert alert;
    
    public BudgetAlertEvent(Object source, Long userId, BudgetAlert alert) {
        super(source);
        this.userId = userId;
        this.alert = alert;
    }
}

// Publisher (BudgetService)
@Service
public class BudgetService {
    private final ApplicationEventPublisher eventPublisher;
    
    public void checkBudgetAlerts(Long userId, Long categoryId) {
        // Logic to check budget
        if (budgetExceeded) {
            BudgetAlertEvent event = new BudgetAlertEvent(this, userId, alert);
            eventPublisher.publishEvent(event);
        }
    }
}

// Subscribers listen and react
@Component
public class EmailNotificationListener {
    @EventListener
    public void handleBudgetAlert(BudgetAlertEvent event) {
        // Send email notification
    }
}

@Component
public class InAppNotificationListener {
    @EventListener
    public void handleBudgetAlert(BudgetAlertEvent event) {
        // Create in-app notification
    }
}

// Benefits:
// - Loose coupling between services
// - Multiple subscribers can react to same event
// - Easy to add new notification types
```

---

## Security Architecture

### 13.1 Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                              │
└─────────────────────────────────────────────────────────────────┘

Layer 1: Network Level
├─ HTTPS/TLS encryption (1.2+)
├─ Load balancer with WAF (optional)
└─ DDoS protection

Layer 2: Application Entry Point
├─ CORS validation
├─ Request size limits
├─ Rate limiting
└─ Request validation

Layer 3: Authentication
├─ JWT token-based auth
├─ Token signature verification
├─ Token expiration checks
└─ Blacklist checking

Layer 4: Authorization
├─ Role-based access control (RBAC)
├─ Method-level security (@PreAuthorize)
├─ Resource ownership verification
└─ Audit logging

Layer 5: Input Validation
├─ Request body validation (@Valid)
├─ Parameter validation
├─ Type checking
└─ SQL injection prevention (parameterized queries)

Layer 6: Business Logic
├─ Data consistency checks
├─ Transaction isolation
├─ Optimistic/pessimistic locking
└─ Business rule enforcement

Layer 7: Data Protection
├─ Sensitive data encryption at rest
├─ PII masking in logs
├─ Secure password hashing (BCrypt)
└─ Field-level encryption (optional)

Layer 8: Data Layer
├─ Database access control
├─ Row-level security (if supported)
├─ Audit trail logging
└─ Regular backups
```

### 13.2 Specific Security Implementations

#### Password Security

```java
@Configuration
public class SecurityConfig {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt with strength 12 (takes ~100ms to hash)
        return new BCryptPasswordEncoder(12);
    }
}

// Usage in service:
@Service
public class UserService {
    private final PasswordEncoder passwordEncoder;
    
    public void registerUser(RegisterDTO dto) {
        String hashedPassword = passwordEncoder.encode(dto.getPassword());
        user.setPassword(hashedPassword);
    }
    
    public boolean verifyPassword(String rawPassword, String hashedPassword) {
        return passwordEncoder.matches(rawPassword, hashedPassword);
    }
}

// Security features:
// - BCrypt with salt prevents rainbow table attacks
// - Strength 12: ~100ms per hash, resistant to brute force
// - Each password has unique salt
// - Adaptive: can increase strength as computers get faster
```

#### SQL Injection Prevention

```java
// VULNERABLE - Don't do this:
String query = "SELECT * FROM users WHERE email = '" + email + "'";
entityManager.createNativeQuery(query);

// SAFE - Parameterized queries:
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// Or with Spring Data:
Optional<User> findByEmail(String email);  // Auto-parameterized

// With native query:
@Query(value = "SELECT * FROM users WHERE email = ?1", nativeQuery = true)
Optional<User> findByEmailNative(String email);
```

#### CSRF Protection

```java
// Spring Security handles CSRF by default for state-changing operations
// Token automatically added to forms and validated on POST/PUT/DELETE

@Configuration
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
            );
        return http.build();
    }
}

// CSRF token automatically:
// - Generated per session
// - Included in response headers
// - Validated on POST/PUT/DELETE requests
// - Prevents cross-site form submissions
```

#### XSS Prevention

```java
// Input Validation (Backend)
@Entity
public class Expense {
    @Column(length = 1000)
    @NotBlank
    private String description;  // Max length enforced
}

// Output Encoding (Frontend with React)
// React automatically escapes content:
<div>{expense.description}</div>  // Safe - automatically escaped

// Dangerous - renders HTML:
<div dangerouslySetInnerHTML={{__html: expense.description}} />
// Only use for trusted content!

// Response headers for XSS protection:
@Configuration
public class WebConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("https://domain.com")
                    .allowedMethods("GET", "POST", "PUT", "DELETE")
                    .allowCredentials(true);
            }
        };
    }
}
```

#### Access Control

```java
// Method-level security:
@Service
public class ExpenseService {
    
    @PreAuthorize("hasRole('USER')")  // Only logged-in users
    public List<Expense> getExpenses(Long userId) {
        return repository.findByUserId(userId);
    }
    
    @PreAuthorize("hasRole('ADMIN')")  // Only admins
    public void deleteExpense(Long expenseId) {
        repository.deleteById(expenseId);
    }
}

// Resource ownership check:
@PostAuthorize("returnObject.userId == authentication.principal.id")
public Expense getExpense(Long expenseId) {
    return repository.findById(expenseId).orElseThrow();
}

// Field-level security:
@Service
public class ExpenseService {
    
    public Expense getExpense(Long expenseId, Long userId) {
        Expense expense = repository.findById(expenseId).orElseThrow();
        
        // Verify user owns expense
        if (!expense.getUserId().equals(userId)) {
            throw new ForbiddenException("Access denied");
        }
        
        return expense;
    }
}
```

### 13.3 JWT Secret Management

```yaml
# Never commit secrets to repository!
# Use environment variables:

# application-prod.yml
spring:
  jwt:
    secret: ${JWT_SECRET}  # Injected from environment
    expiration: 86400000

# For development (application-dev.yml):
spring:
  jwt:
    secret: dev-secret-only-for-testing
    expiration: 86400000

# Deployment:
export JWT_SECRET="$(openssl rand -base64 32)"  # Generate random secret
docker run -e JWT_SECRET="$JWT_SECRET" app-image

# Or with Kubernetes secrets:
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  JWT_SECRET: "base64-encoded-secret"
  DB_PASSWORD: "..."
```

---

## Deployment Architecture

### 14.1 Containerization

```dockerfile
# Dockerfile for backend
FROM openjdk:17-slim AS build

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:resolve

# Copy source code and build
COPY . .
RUN mvn clean package -DskipTests

# Runtime stage (minimal image)
FROM openjdk:17-slim

WORKDIR /app

# Copy built JAR from build stage
COPY --from=build /app/target/expense-tracker-*.jar app.jar

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-Xmx512m", "-Xms256m", "-XX:+UseG1GC", "-jar", "app.jar"]

# Dockerfile for frontend
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 14.2 Docker Compose for Local Development

```yaml
version: '3.8'

services:
  # Backend API
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/expense_tracker
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      SPRING_JPA_HIBERNATE_DDL_AUTO: validate
      JWT_SECRET: ${JWT_SECRET}
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    environment:
      REACT_APP_API_URL: http://localhost:8080/api/v1
    depends_on:
      - backend

  # MySQL Database
  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: expense_tracker
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache (Optional)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  mysql_data:
  redis_data:
```

### 14.3 Kubernetes Deployment

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: expense-tracker

---
# configmap.yaml (non-sensitive configuration)
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: expense-tracker
data:
  DATABASE_URL: "jdbc:mysql://mysql-service:3306/expense_tracker"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"

---
# secret.yaml (sensitive data)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: expense-tracker
type: Opaque
data:
  DB_USER: ZXhwZW5zZXR1c2Vy  # base64 encoded
  DB_PASSWORD: c2VjdXJlcGFzc3dvcmQ=
  JWT_SECRET: am9pY29tZXdpdGhjb21wbGV4dGhpbmdzaGVyZQ==

---
# mysql-deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: expense-tracker
spec:
  serviceName: mysql-service
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_DATABASE
          value: "expense_tracker"
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi

---
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: expense-tracker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: expense-tracker/backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_URL
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_USER
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: JWT_SECRET
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5

---
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: expense-tracker
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
    name: http

---
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: expense-tracker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: expense-tracker/frontend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          value: "https://api.expense-tracker.com/api/v1"
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10

---
# frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: expense-tracker
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80

---
# ingress.yaml (for routing)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: expense-tracker-ingress
  namespace: expense-tracker
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - expense-tracker.com
    - api.expense-tracker.com
    secretName: tls-secret
  rules:
  - host: expense-tracker.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  - host: api.expense-tracker.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80

---
# hpa.yaml (Horizontal Pod Autoscaling)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: expense-tracker
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## Sequence Diagrams

### 15.1 User Login Sequence

```
┌─────────┐        ┌──────────────────┐        ┌──────────────────┐        ┌──────────┐
│ Browser │        │   React App      │        │  Spring Boot     │        │  MySQL   │
└────┬────┘        └────────┬─────────┘        └────────┬─────────┘        └────┬─────┘
     │                       │                           │                        │
     │  1. User submits      │                           │                        │
     │  login form           │                           │                        │
     ├──────────────────────>│                           │                        │
     │                       │                           │                        │
     │                       │ 2. POST /api/v1/auth/login│                        │
     │                       │  (email, password)        │                        │
     │                       ├──────────────────────────>│                        │
     │                       │                           │                        │
     │                       │                           │ 3. Find user by email│
     │                       │                           ├───────────────────────>│
     │                       │                           │                        │
     │                       │                           │<── User data returned ──│
     │                       │                           │                        │
     │                       │                           │ 4. Validate password   │
     │                       │                           │  (BCrypt.matches)      │
     │                       │                           │                        │
     │                       │                           │ 5. Generate JWT tokens │
     │                       │                           │  - ACCESS_TOKEN (24h)  │
     │                       │                           │  - REFRESH_TOKEN (7d)  │
     │                       │                           │                        │
     │                       │ 6. Return tokens         │                        │
     │                       │  { accessToken,          │                        │
     │                       │    refreshToken,         │                        │
     │                       │    user info }           │                        │
     │                       │<──────────────────────────│                        │
     │                       │                           │                        │
     │                       │ 7. Store tokens (Redux) │                        │
     │                       │    accessToken → memory  │                        │
     │                       │    refreshToken → cookie │                        │
     │                       │                           │                        │
     │ 8. Display dashboard  │                           │                        │
     │<──────────────────────┤                           │                        │
     │                       │                           │                        │

Alternative - Login Failure:
     │                       │ 2. POST /api/v1/auth/login│                        │
     │                       ├──────────────────────────>│                        │
     │                       │                           │                        │
     │                       │                           │ 3. Find user by email│
     │                       │                           ├───────────────────────>│
     │                       │                           │<── User not found ─────│
     │                       │                           │                        │
     │                       │ 4. Return 401 Unauthorized│                        │
     │                       │  { error: "Invalid creds"}│                        │
     │                       │<──────────────────────────│                        │
     │                       │                           │                        │
     │ 5. Display error msg  │                           │                        │
     │<──────────────────────┤                           │                        │
     │                       │                           │                        │
```

### 15.2 Add Expense Sequence

```
┌──────────┐        ┌────────────────────┐        ┌─────────────────┐        ┌──────────┐
│ Browser  │        │   React App        │        │  Spring Boot    │        │  MySQL   │
└────┬─────┘        └────────┬───────────┘        └────────┬────────┘        └────┬─────┘
     │                        │                            │                       │
     │  1. User fills form    │                            │                       │
     │  and submits           │                            │                       │
     ├───────────────────────>│                            │                       │
     │                        │                            │                       │
     │                        │ 2. HTTP Interceptor        │                       │
     │                        │  - Extract JWT token       │                       │
     │                        │  - Add Authorization header│                       │
     │                        │                            │                       │
     │                        │ 3. POST /api/v1/expenses   │                       │
     │                        │  Headers: {                │                       │
     │                        │    Authorization: Bearer.. │                       │
     │                        │  }                         │                       │
     │                        │  Body: {                   │                       │
     │                        │    amount, category,       │                       │
     │                        │    date, description       │                       │
     │                        │  }                         │                       │
     │                        ├───────────────────────────>│                       │
     │                        │                            │                       │
     │                        │                            │ 4. JwtAuthenticationFilter
     │                        │                            │  - Extract token      │
     │                        │                            │  - Validate signature │
     │                        │                            │  - Verify expiration  │
     │                        │                            │  - Create auth object │
     │                        │                            │  - Set SecurityContext│
     │                        │                            │                       │
     │                        │                            │ 5. ExpenseController  │
     │                        │                            │  - @Valid validation  │
     │                        │                            │  - Get userId from auth
     │                        │                            │                       │
     │                        │                            │ 6. @Transactional    │
     │                        │                            │  - Begin transaction  │
     │                        │                            │                       │
     │                        │                            │ 7. ExpenseService    │
     │                        │                            │  - Validate data     │
     │                        │                            │ 8. Fetch Category    │
     │                        │                            ├──────────────────────>│
     │                        │                            │← Category entity ─────│
     │                        │                            │                       │
     │                        │                            │ 9. Create Expense    │
     │                        │                            │    entity             │
     │                        │                            │                       │
     │                        │                            │ 10. Save to DB       │
     │                        │                            ├──────────────────────>│
     │                        │                            │  INSERT expense row   │
     │                        │                            │← ID auto-generated ───│
     │                        │                            │                       │
     │                        │                            │ 11. BudgetService    │
     │                        │                            │  - Check budget alerts│
     │                        │                            │ 12. NotificationSvc  │
     │                        │                            │  - Send email/in-app  │
     │                        │                            │                       │
     │                        │                            │ 13. Clear cache       │
     │                        │                            │ 14. Commit transaction
     │                        │                            │                       │
     │                        │ 15. Return 201 Created    │                       │
     │                        │  Location: /api/v1/       │                       │
     │                        │    expenses/123           │                       │
     │                        │  Body: { expense data }   │                       │
     │                        │<───────────────────────────│                       │
     │                        │                            │                       │
     │                        │ 16. Redux update state    │                       │
     │                        │ 17. Re-render list        │                       │
     │ 18. Show success msg   │                            │                       │
     │<───────────────────────┤                            │                       │
     │                        │                            │                       │
```

---

## Future Scalability Considerations

### 16.1 Horizontal Scaling Strategy

```
Current Architecture (Phase 1):
┌─────────────────────────┐
│  Load Balancer (Nginx)  │
└────────────┬────────────┘
             │
    ┌────────┴────────┐
    │                 │
    ↓                 ↓
┌─────────┐      ┌─────────┐
│App Inst.│      │App Inst.│  (2-3 instances)
│    1    │      │    2    │
└────┬────┘      └────┬────┘
     │                │
     └────────┬───────┘
              │
         ┌────┴────┐
         │  Cache  │
         │ (Redis) │
         └────┬────┘
              │
    ┌─────────┴──────────┐
    │                    │
    ↓                    ↓
┌─────────┐         ┌──────────┐
│ MySQL   │         │ MySQL    │
│ Master  │────────>│ Replica  │
│ (Write) │  Sync   │ (Read)   │
└─────────┘         └──────────┘
```

### 16.2 Phase 2 Scaling (6-12 months)

```
Advanced Caching:
├─ Query result caching (Redis)
├─ Category caching
├─ User preference caching
├─ Report computation caching
└─ Cache invalidation strategies

Database Optimization:
├─ Read replicas for analytics queries
├─ Query optimization and indexing
├─ Partitioning for large tables
│  ├─ Partition Expenses by userId
│  └─ Archive old expense data
├─ Aggregation tables for reports
└─ Materialized views

Asynchronous Processing:
├─ Budget alert notifications (async)
├─ Report generation (background job)
├─ Email sending (message queue)
├─ Data import processing (async)
└─ Use: Spring Async, Kafka, or RabbitMQ

CDN for Static Assets:
├─ Frontend bundles to CloudFront
├─ Images to CDN
└─ Reduces backend load
```

### 16.3 Phase 3 Scaling (9-18 months)

```
Microservices Architecture:
├─ Auth Service (separate)
├─ Expense Service
├─ Budget & Analytics Service
├─ Notification Service
├─ User Service
└─ Communication via:
   ├─ REST/gRPC
   └─ Message Queue (Kafka)

Data Scaling:
├─ Database sharding by userId
│  ├─ Shard 1: userId 0-1000
│  ├─ Shard 2: userId 1001-2000
│  └─ Shard lookup service
├─ Time-series DB for metrics
│  └─ InfluxDB or Prometheus
└─ Search engine for expenses
   └─ Elasticsearch for full-text search

Service Mesh:
├─ Istio for service-to-service communication
├─ Traffic management
├─ Service discovery
├─ Circuit breakers
└─ Distributed tracing

Event-Driven Architecture:
├─ Kafka topics:
│  ├─ expense-created
│  ├─ expense-deleted
│  ├─ budget-exceeded
│  └─ user-registered
└─ Multiple consumers subscribe to events
```

### 16.4 Monitoring & Observability

```
Metrics Collection:
├─ Application metrics (Micrometer)
│  ├─ API response times
│  ├─ Request counts
│  ├─ Error rates
│  ├─ Database query times
│  └─ Cache hit rates
├─ JVM metrics
│  ├─ Memory usage
│  ├─ GC pauses
│  └─ Thread counts
└─ Business metrics
   ├─ User sign-ups
   ├─ Expenses created
   └─ Revenue (if applicable)

Logging:
├─ Structured logging (JSON)
├─ Log levels: DEBUG, INFO, WARN, ERROR
├─ ELK Stack for aggregation
│  ├─ Elasticsearch for storage
│  ├─ Logstash for processing
│  └─ Kibana for visualization
└─ Log retention: 30-90 days

Tracing:
├─ Distributed tracing (Jaeger)
├─ Trace requests across services
├─ Identify bottlenecks
└─ Performance analysis

Alerting:
├─ Error rate > 5%
├─ Response time P95 > 2 seconds
├─ Database query time > 1 second
├─ Cache hit rate < 80%
├─ Memory usage > 80%
└─ Disk usage > 80%
```

### 16.5 Load Testing Strategy

```
Load Testing Tools:
├─ Apache JMeter
├─ Gatling
├─ Artillery
└─ k6

Test Scenarios:
├─ Baseline: 100 concurrent users
├─ Normal load: 500 concurrent users
├─ Peak load: 1000 concurrent users
├─ Stress test: 5000 concurrent users

Endpoints to Test:
├─ GET /api/v1/expenses (paginated list)
├─ POST /api/v1/expenses (create)
├─ GET /api/v1/reports/summary (report generation)
├─ GET /api/v1/budgets/{month} (budget check)
└─ POST /api/v1/auth/login (authentication)

Performance Targets:
├─ P95 response time: < 500ms
├─ P99 response time: < 1s
├─ Error rate: < 0.1%
├─ Database connection pool: < 80% utilization
└─ Cache hit ratio: > 80%
```

---

## References

### Technology Documentation

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Security Reference](https://spring.io/projects/spring-security)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [React Documentation](https://react.dev)
- [Redux Documentation](https://redux.js.org)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [JWT.io](https://jwt.io)
- [OWASP Security Guidelines](https://owasp.org)
- [RESTful API Best Practices](https://restfulapi.net)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com)

### Architecture Patterns

- [Design Patterns: Elements of Reusable Object-Oriented Software](https://en.wikipedia.org/wiki/Design_Patterns)
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)
- [Microservices Patterns](https://microservices.io/patterns/index.html)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Security References

- [OWASP Top 10 Web Application Security Risks](https://owasp.org/www-project-top-ten/)
- [Spring Security in Action](https://www.manning.com/books/spring-security-in-action)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

## Document Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Architect | __________ | __________ | __________ |
| Lead Developer (Backend) | __________ | __________ | __________ |
| Lead Developer (Frontend) | __________ | __________ | __________ |
| DevOps Lead | __________ | __________ | __________ |
| Project Manager | __________ | __________ | __________ |

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | July 2026 | Architecture Team | Initial SAD document |

---

**Document Classification:** Internal - Not Confidential  
**Distribution:** Development Team, Architects, DevOps Team, GitHub Repository

*This document is subject to change based on architecture decisions and project evolution.*
