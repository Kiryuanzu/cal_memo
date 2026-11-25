// The document Meta Muse reads to learn how to call this API.
// Descriptions are written for an AI reader: say what each field means and when to use each endpoint.
// /sync is intentionally left out: it is for the local cal_memo app only.

const dateParam = (name: "from" | "to", description: string) => ({
  name,
  in: "query",
  required: false,
  description,
  schema: { type: "string", format: "date", example: "2026-11-24" },
});

const rangeParams = [
  dateParam("from", "First day of the range (inclusive), Japan local date. Give both from and to, or neither (defaults to the last 7 days)."),
  dateParam("to", "Last day of the range (inclusive), Japan local date. The range may span at most 366 days."),
];

const lastSyncedAt = {
  type: "string",
  format: "date-time",
  nullable: true,
  description: "When the data was last uploaded from the owner's app. Logs eaten after this moment are not included yet.",
};

export function buildOpenApiDocument(serverUrl: string) {
  return {
    openapi: "3.0.3",
    info: {
      title: "cal_memo meal log API",
      version: "1.0.0",
      description:
        "Read-only access to one person's daily meal log (what they ate, calories in kcal, protein in grams). " +
        "Dates are Japan local dates. Data is synced manually, so check last_synced_at before concluding that a day has no meals.",
    },
    servers: [{ url: serverUrl }],
    security: [{ bearerAuth: [] }],
    components: {
      securitySchemes: { bearerAuth: { type: "http", scheme: "bearer" } },
      schemas: {
        FoodLog: {
          type: "object",
          properties: {
            id: { type: "integer" },
            date: { type: "string", format: "date", description: "Day the food was eaten." },
            meal_type: { type: "string", enum: ["breakfast", "lunch", "dinner", "snack"] },
            food_name: { type: "string", description: "Food name, usually Japanese." },
            calories: { type: "integer", description: "Energy in kcal." },
            protein_g: { type: "integer", description: "Protein in grams." },
            food_group: { type: "string", description: "Rough nutritional group, e.g. staple, main, side, snack." },
            comment: { type: "string", nullable: true, description: "Free-text note written by the person." },
          },
          required: ["id", "date", "meal_type", "food_name", "calories", "protein_g", "food_group", "comment"],
        },
      },
    },
    paths: {
      "/logs": {
        get: {
          operationId: "listMealLogs",
          summary: "List individual meal entries in a date range",
          description: "Use this to see exactly what was eaten. Entries are ordered by date, then breakfast, lunch, dinner, snack.",
          parameters: rangeParams,
          responses: {
            "200": {
              description: "Meal entries",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      from: { type: "string", format: "date" },
                      to: { type: "string", format: "date" },
                      last_synced_at: lastSyncedAt,
                      logs: { type: "array", items: { $ref: "#/components/schemas/FoodLog" } },
                    },
                  },
                },
              },
            },
            "400": { description: "Invalid date range" },
            "401": { description: "Missing or wrong bearer token" },
          },
        },
      },
      "/summary": {
        get: {
          operationId: "summarizeMealLogs",
          summary: "Daily calorie and protein totals in a date range",
          description:
            "Use this for trends and totals. Days without any entries are omitted, so days_with_logs can be smaller than the number of days in the range.",
          parameters: rangeParams,
          responses: {
            "200": {
              description: "Totals",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      from: { type: "string", format: "date" },
                      to: { type: "string", format: "date" },
                      last_synced_at: lastSyncedAt,
                      total: {
                        type: "object",
                        properties: {
                          calories: { type: "integer" },
                          protein_g: { type: "integer" },
                          days_with_logs: { type: "integer" },
                        },
                      },
                      days: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: {
                            date: { type: "string", format: "date" },
                            calories: { type: "integer" },
                            protein_g: { type: "integer" },
                            meals: {
                              type: "object",
                              description: "Calories per meal type for the day.",
                              properties: {
                                breakfast: { type: "integer" },
                                lunch: { type: "integer" },
                                dinner: { type: "integer" },
                                snack: { type: "integer" },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
            "400": { description: "Invalid date range" },
            "401": { description: "Missing or wrong bearer token" },
          },
        },
      },
    },
  };
}
