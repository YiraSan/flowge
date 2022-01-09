import { Token } from "rale";

/**
 * Instruction (as string[]) are currently in phase to change
 */
export function parseMethod(str: string|Token[], isAScript: boolean): {
    instruction: string[],
    imports: string[][],
} {
    throw "Unimplemented Function"
}