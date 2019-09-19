using System;

namespace SuperJMN.MonoGame.Common
{
    public class Alignment
    {
        public Alignment(AnchorPoint subject, AnchorPoint guide)
        {
            Subject = subject;
            Guide = guide;
        }

        public AnchorPoint Subject { get; }
        public AnchorPoint Guide { get; }

        public static Alignment ToRightSide = new Alignment(AnchorPoint.CenterRight, AnchorPoint.CenterLeft);
        public static Alignment ToLeftSide = new Alignment(AnchorPoint.CenterLeft, AnchorPoint.CenterRight);
        public static Alignment ToBottomSide = new Alignment(AnchorPoint.Top, AnchorPoint.Bottom);
        public static Alignment ToTopSide = new Alignment(AnchorPoint.Bottom, AnchorPoint.Top);
        public static Alignment JoinBottoms = new Alignment(AnchorPoint.Bottom, AnchorPoint.Bottom);
        public static Alignment JoinTops = new Alignment(AnchorPoint.Top, AnchorPoint.Top);
        public static Alignment Center = new Alignment(AnchorPoint.Center, AnchorPoint.Center);
    }

    public static class RectangleExtensions
    {
        public static void SetWidth(this IRectangle rectangle, double width, IReadonlyRectangle reference)
        {
            rectangle.Width = width;
            var proportion = reference.Width / reference.Height;
            rectangle.Height = width / proportion;
        }

        public static void SetHeight(this IRectangle rectangle, double height, IReadonlyRectangle reference)
        {
            rectangle.Height = height;
            var proportion = reference.Width / reference.Height;
            rectangle.Width = height * proportion;
        }

        public static void AlignTo(this IRectangle subject, IReadonlyRectangle guide, Alignment alignment)
        {
            if (alignment.Subject == AnchorPoint.CenterLeft && alignment.Guide == AnchorPoint.CenterRight)
            {
                subject.Left = guide.Left + guide.Width;
                subject.Top = guide.Top + (guide.Height - subject.Height) / 2;
                return;
            }

            if (alignment.Subject == AnchorPoint.CenterRight && alignment.Guide == AnchorPoint.CenterLeft)
            {
                subject.Left = guide.Left + guide.Width;
                subject.Top = guide.Top + (guide.Height - subject.Height) / 2;
                return;
            }

            if (alignment.Subject == AnchorPoint.Top && alignment.Guide == AnchorPoint.Bottom)
            {
                subject.Left = guide.Left + (guide.Width - subject.Width) / 2;
                subject.Top = guide.Top + guide.Height;
                return;
            }

            if (alignment.Subject == AnchorPoint.Bottom && alignment.Guide == AnchorPoint.Bottom)
            {
                subject.Left = guide.Left + (guide.Width - subject.Width) / 2;
                subject.Top = guide.Top + guide.Height - subject.Height;
                return;
            }

            if (alignment.Subject == AnchorPoint.Center && alignment.Guide == AnchorPoint.Center)
            {
                subject.Left = guide.Left + (guide.Width - subject.Width) / 2;
                subject.Top = guide.Top + (guide.Height - subject.Height) / 2;
                return;
            }

            throw new InvalidOperationException("The alignment is not supported");
        }
    }
}