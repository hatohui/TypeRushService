# 🚀 Swagger UI Setup - Complete Guide

## ✅ Configuration Complete!

Your Swagger UI is now configured globally and will **automatically display ALL API endpoints** from every controller in your NestJS application.

---

## 📍 Access Your API Documentation

**URL:** http://localhost:3000/api/docs

Start your application and visit the URL above to see all your endpoints.

---

## 🔧 How It Works - Automatic Controller Discovery

### **No Manual Registration Required!**

The Swagger configuration in `main.ts` uses this powerful line:

```typescript
const document = SwaggerModule.createDocument(app, config);
```

This **automatically scans your entire application** and includes:

✅ **All Controllers** - Any class with `@Controller()` decorator  
✅ **All Endpoints** - Methods with `@Get()`, `@Post()`, `@Put()`, `@Patch()`, `@Delete()`  
✅ **All Modules** - Controllers from every imported module in `AppModule`  
✅ **Shared Database** - No configuration needed since all modules share one Prisma instance

### **What Gets Included Automatically:**

```
AppModule
├── PersonalRecordModule → PersonalRecordController ✅ Included
├── ModeModule → ModeController ✅ Included
├── MatchHistoryModule → MatchHistoryController ✅ Included
├── MatchParticipantModule → MatchParticipantController ✅ Included
├── AchievementModule → AchievementController ✅ Included
└── UserAchievementModule → UserAchievementController ✅ Included
```

**All controllers are discovered and documented automatically!**

---

## 🔑 Using JWT Authentication

### Step 1: Get Your JWT Token

Authenticate with your auth service to get a token:

```bash
curl -X POST http://your-auth-service/login \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "pass"}'
```

Response:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Step 2: Authorize in Swagger UI

1. Click the **🔒 "Authorize"** button at the top right
2. Paste your JWT token (without "Bearer" prefix)
3. Click **"Authorize"**
4. Click **"Close"**

✅ **Your token is now saved and persists even after page reload!**

---

## 🎯 Configured Features

| Feature                | Status        | Description                                |
| ---------------------- | ------------- | ------------------------------------------ |
| **Global Discovery**   | ✅ Enabled    | All controllers auto-discovered            |
| **JWT Bearer Auth**    | ✅ Configured | `addBearerAuth()` with JWT-auth identifier |
| **Persistent Token**   | ✅ Enabled    | Token saved after page reload              |
| **Collapsed Sections** | ✅ Enabled    | All endpoints collapsed by default         |
| **Search/Filter**      | ✅ Enabled    | Filter endpoints by keyword                |
| **Request Duration**   | ✅ Enabled    | Shows API response time                    |
| **Clean UI**           | ✅ Styled     | Custom CSS for professional look           |

---

## 📋 Testing Your APIs

### 1. **Expand an Endpoint**

- Click on any endpoint (e.g., `GET /personal-records`)

### 2. **Click "Try it out"**

- Enables the interactive request form

### 3. **Fill in Parameters**

- Path parameters (e.g., `id`)
- Query parameters (e.g., `page`, `limit`)
- Request body (for POST/PUT/PATCH)

### 4. **Click "Execute"**

- Request sent with your JWT token automatically
- View response body, status code, and headers

---

## 🎨 Optional: Enhance Controllers with Decorators

To add more details to your Swagger documentation, you can optionally add these decorators to your controllers:

### Add API Tags (Group Endpoints)

```typescript
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Personal Records') // Groups all endpoints under this tag
@Controller('personal-records')
export class PersonalRecordController {
  // ... your methods
}
```

### Require JWT Auth

```typescript
import { ApiBearerAuth } from '@nestjs/swagger';

@ApiBearerAuth('JWT-auth') // Shows lock icon, requires authorization
@Controller('personal-records')
export class PersonalRecordController {
  // ... your methods
}
```

### Document Responses

```typescript
import { ApiOperation, ApiResponse } from '@nestjs/swagger';

@Get(':id')
@ApiOperation({ summary: 'Get record by ID' })
@ApiResponse({ status: 200, description: 'Record found' })
@ApiResponse({ status: 404, description: 'Record not found' })
async findById(@Param('id') id: number) {
  // ... your code
}
```

**Note:** These decorators are **optional**. Your endpoints will still appear in Swagger without them, but they add extra documentation details.

---

## 🔍 Why It Works Automatically

### NestJS Magic Behind the Scenes:

1. **Module System**

   ```typescript
   // app.module.ts imports all your modules
   @Module({
     imports: [
       PersonalRecordModule,
       ModeModule,
       MatchHistoryModule,
       // ... all modules
     ],
   })
   ```

2. **Controller Registration**

   ```typescript
   // Each module declares its controllers
   @Module({
     controllers: [PersonalRecordController],
   })
   ```

3. **Swagger Scanning**

   ```typescript
   // SwaggerModule.createDocument() scans the entire app
   const document = SwaggerModule.createDocument(app, config);
   ```

4. **Result:** All controllers from all modules appear in one Swagger UI! 🎉

---

## 📊 What You'll See in Swagger

When you visit http://localhost:3000/api/docs, you'll see:

```
TypeRush Record Service API v1.0.0

Description with authentication instructions

[Authorize 🔒]  ← Click here to add JWT token

▶ Personal Records
  GET    /personal-records
  POST   /personal-records
  GET    /personal-records/{id}
  PATCH  /personal-records/{id}
  DELETE /personal-records/{id}

▶ Modes
  GET    /modes
  POST   /modes
  GET    /modes/{id}
  PATCH  /modes/{id}
  DELETE /modes/{id}

▶ Match History
  GET    /match-histories
  POST   /match-histories
  GET    /match-histories/{id}
  PATCH  /match-histories/{id}
  DELETE /match-histories/{id}

... and all other controllers automatically!
```

---

## 🐛 Troubleshooting

### Endpoints Not Showing?

**Check:**

1. ✅ Controller has `@Controller()` decorator
2. ✅ Methods have HTTP decorators (`@Get()`, `@Post()`, etc.)
3. ✅ Module is imported in `AppModule`
4. ✅ Application is running (`npm run dev`)

### JWT Authorization Not Working?

**Check:**

1. ✅ Click "Authorize" button and paste token
2. ✅ Token is valid and not expired
3. ✅ Your auth guards are configured correctly
4. ✅ Controller/method has proper auth decorators

### Want to Exclude a Controller?

If you want to hide a controller from Swagger:

```typescript
@ApiExcludeController() // This controller won't appear in Swagger
@Controller('internal')
export class InternalController {
  // ... hidden from docs
}
```

---

## 🎯 Key Takeaways

✅ **Zero Configuration Per Controller** - Just create controllers normally  
✅ **Automatic Discovery** - All endpoints appear automatically  
✅ **Single Shared Database** - Works perfectly with your Prisma setup  
✅ **JWT Authentication** - Configured globally with persistence  
✅ **Production Ready** - Clean UI with all best practices

---

## 📚 Next Steps

1. **Start your application:**

   ```bash
   npm run dev
   ```

2. **Visit Swagger UI:**

   ```
   http://localhost:3000/api/docs
   ```

3. **Authorize with JWT token**

4. **Test all your endpoints!** 🚀

---

**🎉 That's it! Your entire API is now documented and testable in one place.**
