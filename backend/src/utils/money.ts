import { Decimal } from "decimal.js";

/**
 * Wraps every payroll amount so arithmetic never touches a plain JS number.
 * There's no public constructor from a raw number - values only enter via
 * fromDb() (a string straight from the database) or zero(), and only leave
 * via toDbString()/toDisplay(). This makes `basic + hra` a TypeScript error
 * instead of a silent float bug.
 */
export class Money {
  private readonly value: Decimal;

  private constructor(value: Decimal) {
    this.value = value;
  }

  static fromDb(raw: string | number): Money {
    return new Money(new Decimal(raw));
  }

  static zero(): Money {
    return new Money(new Decimal(0));
  }

  plus(other: Money): Money {
    return new Money(this.value.plus(other.value));
  }

  minus(other: Money): Money {
    return new Money(this.value.minus(other.value));
  }

  times(factor: number): Money {
    return new Money(this.value.times(factor));
  }

  isNegative(): boolean {
    return this.value.isNegative();
  }

  equals(other: Money): boolean {
    return this.value.equals(other.value);
  }

  toDbString(): string {
    return this.value.toFixed(2);
  }

  toDisplay(): string {
    return `\u20b9${this.value.toFixed(2)}`;
  }
}
