import axios from "axios";
import { readFileSync } from "fs";
import { join } from "path";

const configFile = join(__dirname, "../packages/frontend/.env");
const envContent = readFileSync(configFile, "utf-8");
const envVars = Object.fromEntries(
  envContent
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim())
    .filter((line) => line.includes("="))
    .map((line) => line.split("="))
);

const API_URL = `http://localhost:4566/_aws/execute-api/${envVars.VITE_GATEWAY_ID}/prod`;
console.log("API URL:", API_URL);

describe("Notes API Integration Tests", () => {
  let noteId: string;

  const testNote = {
    content: "Test note content",
  };

  const updatedNote = {
    content: "Updated note content",
  };

  const api = axios.create({
    baseURL: API_URL,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
  });

  test("should create a new note", async () => {
    const response = await api.post("/notes", testNote);
    expect(response.status).toBe(200);
    const data = response.data;
    expect(data).toBeDefined();
    expect(data.content.S).toBe(testNote.content);
    noteId = data.noteId.S;
  });

  test("should list all notes", async () => {
    const response = await api.get("/notes");
    expect(response.status).toBe(200);
    const data = response.data;
    expect(Array.isArray(data)).toBeTruthy();
    expect(data.length).toBeGreaterThan(0);
    const createdNote = data.find((note: any) => note.noteId === noteId);
    expect(createdNote).toBeDefined();
    expect(createdNote.content).toBe(testNote.content);
  });

  test("should get a specific note", async () => {
    const response = await api.get(`/notes/${noteId}`);
    expect(response.status).toBe(200);
    const data = response.data;
    expect(data).toBeDefined();
    expect(data.noteId).toBe(noteId);
    expect(data.content).toBe(testNote.content);
  });

  test("should update a note", async () => {
    const response = await api.put(`/notes/${noteId}`, updatedNote);
    expect(response.status).toBe(200);
    const data = response.data;
    expect(data).toBeDefined();
    expect(data.status).toBe(true);

    // Verify the update
    const getResponse = await api.get(`/notes/${noteId}`);
    expect(getResponse.status).toBe(200);
    expect(getResponse.data.content).toBe(updatedNote.content);
  });

  test("should delete a note", async () => {
    const response = await api.delete(`/notes/${noteId}`);
    expect(response.status).toBe(200);
    expect(response.data.status).toBe(true);

    // Verify the note is deleted
    const getResponse = await api.get(`/notes`);

    // Check if the note is not in the list
    const data = getResponse.data;
    expect(Array.isArray(data)).toBeTruthy();
    const deletedNote = data.find((note: any) => note.noteId === noteId);
    expect(deletedNote).toBeUndefined();
  });
});
